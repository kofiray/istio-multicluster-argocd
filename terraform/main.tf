terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
  }
  required_version = ">= 1.0.0"
}

provider "azurerm" {
  features {}
}

# Helm provider configuration for UK South cluster
provider "helm" {
  alias = "uksouth"
  kubernetes {
    host                   = azurerm_kubernetes_cluster.uksouth.kube_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.uksouth.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.uksouth.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.uksouth.kube_config.0.cluster_ca_certificate)
  }
}

# Helm provider configuration for UK West cluster
provider "helm" {
  alias = "ukwest"
  kubernetes {
    host                   = azurerm_kubernetes_cluster.ukwest.kube_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.ukwest.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.ukwest.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.ukwest.kube_config.0.cluster_ca_certificate)
  }
}

# Kubernetes provider for UK South
provider "kubernetes" {
  alias                  = "uksouth"
  host                   = azurerm_kubernetes_cluster.uksouth.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.uksouth.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.uksouth.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.uksouth.kube_config.0.cluster_ca_certificate)
}

# Kubernetes provider for UK West
provider "kubernetes" {
  alias                  = "ukwest"
  host                   = azurerm_kubernetes_cluster.ukwest.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.ukwest.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.ukwest.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.ukwest.kube_config.0.cluster_ca_certificate)
}

# Create Resource Group
resource "azurerm_resource_group" "frontdoor_rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Create Front Door Profile
resource "azurerm_cdn_frontdoor_profile" "profile" {
  name                = var.frontdoor_profile_name
  resource_group_name = azurerm_resource_group.frontdoor_rg.name
  sku_name            = var.frontdoor_sku_name
  tags                = var.tags
}

# Create Front Door Endpoint
resource "azurerm_cdn_frontdoor_endpoint" "endpoint" {
  name                     = var.frontdoor_endpoint_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.profile.id
  tags                     = var.tags
}

# Get Istio Gateway Service IPs
data "kubernetes_service" "istio_gateway_uksouth" {
  provider = kubernetes.uksouth
  metadata {
    name      = "istio-gateway"
    namespace = "istio-system"
  }
}

data "kubernetes_service" "istio_gateway_ukwest" {
  provider = kubernetes.ukwest
  metadata {
    name      = "istio-gateway"
    namespace = "istio-system"
  }
}

# Create Front Door Origin Group
resource "azurerm_cdn_frontdoor_origin_group" "origin_group" {
  name                     = var.frontdoor_origin_group_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.profile.id
  session_affinity_enabled = true

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 2
    additional_latency_in_milliseconds = 0
  }

  health_probe {
    interval_in_seconds = 30
    path                = "/healthz/ready"
    protocol            = "Http"
    request_type        = "GET"
  }
}

# Create Front Door Origin for UK South
resource "azurerm_cdn_frontdoor_origin" "origin_uksouth" {
  name                          = var.frontdoor_origin_name_uksouth
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.origin_group.id
  enabled                       = true

  certificate_name_check_enabled = false
  host_name                      = data.kubernetes_service.istio_gateway_uksouth.status[0].load_balancer[0].ingress[0].ip
  http_port                      = 80
  https_port                     = 80
  origin_host_header             = var.app_hostname
  priority                       = 1
  weight                         = 50

  depends_on = [
    data.kubernetes_service.istio_gateway_uksouth
  ]
}

# Create Front Door Origin for UK West
resource "azurerm_cdn_frontdoor_origin" "origin_ukwest" {
  name                          = var.frontdoor_origin_name_ukwest
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.origin_group.id
  enabled                       = true

  certificate_name_check_enabled = false
  host_name                      = data.kubernetes_service.istio_gateway_ukwest.status[0].load_balancer[0].ingress[0].ip
  http_port                      = 80
  https_port                     = 80
  origin_host_header             = var.app_hostname
  priority                       = 1
  weight                         = 50

  depends_on = [
    data.kubernetes_service.istio_gateway_ukwest
  ]
}

# Create Front Door Route
resource "azurerm_cdn_frontdoor_route" "route" {
  name                          = var.frontdoor_route_name
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.endpoint.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.origin_group.id
  cdn_frontdoor_origin_ids      = [
    azurerm_cdn_frontdoor_origin.origin_uksouth.id,
    azurerm_cdn_frontdoor_origin.origin_ukwest.id
  ]
  enabled                       = true

  forwarding_protocol    = "HttpOnly"
  https_redirect_enabled = true
  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]

  link_to_default_domain = true

  cache {
    query_string_caching_behavior = "UseQueryString"
    compression_enabled           = true
    content_types_to_compress     = ["text/html", "text/javascript", "text/css", "application/json"]
  }
}

# Create ArgoCD namespace in UK South
resource "kubernetes_namespace" "argocd_uksouth" {
  provider = kubernetes.uksouth
  metadata {
    name = "argocd"
  }
}

# Create ArgoCD namespace in UK West
resource "kubernetes_namespace" "argocd_ukwest" {
  provider = kubernetes.ukwest
  metadata {
    name = "argocd"
  }
}

# Install ArgoCD in UK South cluster
resource "helm_release" "argocd_uksouth" {
  provider   = helm.uksouth
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_helm_version
  namespace  = kubernetes_namespace.argocd_uksouth.metadata[0].name

  values = [
    yamlencode({
      server = {
        extraArgs = ["--insecure"]
        service = {
          type = "LoadBalancer"
        }
      }
      controller = {
        replicas = 1
      }
      repoServer = {
        replicas = 1
      }
      applicationSet = {
        enabled = true
      }
      ha = {
        enabled = true
      }
    })
  ]
}

# Install ArgoCD in UK West cluster
resource "helm_release" "argocd_ukwest" {
  provider   = helm.ukwest
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_helm_version
  namespace  = kubernetes_namespace.argocd_ukwest.metadata[0].name

  values = [
    yamlencode({
      server = {
        extraArgs = ["--insecure"]
        service = {
          type = "LoadBalancer"
        }
      }
      controller = {
        replicas = 1
      }
      repoServer = {
        replicas = 1
      }
      applicationSet = {
        enabled = true
      }
      ha = {
        enabled = true
      }
    })
  ]
} 