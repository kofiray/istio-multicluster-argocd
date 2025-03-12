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
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

# Azure Key Vault data source
data "azurerm_key_vault" "kv" {
  name                = "istio-multicluster-kv"
  resource_group_name = "istio-secrets-rg"
}

data "azurerm_key_vault_secret" "git_pat_token" {
  name         = "git-pat-token"
  key_vault_id = data.azurerm_key_vault.kv.id
}

# Configure Kubernetes Providers
provider "kubernetes" {
  alias = "uksouth"
  host                   = azurerm_kubernetes_cluster.uksouth.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.uksouth.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.uksouth.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.uksouth.kube_config.0.cluster_ca_certificate)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "kubelogin"
    args        = ["get-token", "--login", "azurecli", "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630"]
  }
}

provider "kubernetes" {
  alias = "ukwest"
  host                   = azurerm_kubernetes_cluster.ukwest.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.ukwest.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.ukwest.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.ukwest.kube_config.0.cluster_ca_certificate)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "kubelogin"
    args        = ["get-token", "--login", "azurecli", "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630"]
  }
}

# Configure Helm Providers
provider "helm" {
  alias = "uksouth"
  kubernetes {
    host                   = azurerm_kubernetes_cluster.uksouth.kube_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.uksouth.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.uksouth.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.uksouth.kube_config.0.cluster_ca_certificate)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "kubelogin"
      args        = ["get-token", "--login", "azurecli", "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630"]
    }
  }
}

provider "helm" {
  alias = "ukwest"
  kubernetes {
    host                   = azurerm_kubernetes_cluster.ukwest.kube_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.ukwest.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.ukwest.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.ukwest.kube_config.0.cluster_ca_certificate)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "kubelogin"
      args        = ["get-token", "--login", "azurecli", "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630"]
    }
  }
}

# Configure kubectl Providers
provider "kubectl" {
  alias = "uksouth"
  host                   = azurerm_kubernetes_cluster.uksouth.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.uksouth.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.uksouth.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.uksouth.kube_config.0.cluster_ca_certificate)
  load_config_file       = false
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "kubelogin"
    args        = ["get-token", "--login", "azurecli", "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630"]
  }
}

provider "kubectl" {
  alias = "ukwest"
  host                   = azurerm_kubernetes_cluster.ukwest.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.ukwest.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.ukwest.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.ukwest.kube_config.0.cluster_ca_certificate)
  load_config_file       = false
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "kubelogin"
    args        = ["get-token", "--login", "azurecli", "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630"]
  }
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
  host_name                      = azurerm_kubernetes_cluster.uksouth.kube_config[0].host
  http_port                      = 80
  https_port                     = 80
  origin_host_header             = var.app_hostname
  priority                       = 1
  weight                         = 50
}

# Create Front Door Origin for UK West
resource "azurerm_cdn_frontdoor_origin" "origin_ukwest" {
  name                          = var.frontdoor_origin_name_ukwest
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.origin_group.id
  enabled                       = true

  certificate_name_check_enabled = false
  host_name                      = azurerm_kubernetes_cluster.ukwest.kube_config[0].host
  http_port                      = 80
  https_port                     = 80
  origin_host_header             = var.app_hostname
  priority                       = 1
  weight                         = 50
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

# Create namespace for traffic test in UK South
resource "kubernetes_namespace" "traffic_test_uksouth" {
  provider = kubernetes.uksouth
  metadata {
    name = "traffic-test"
  }
}

# Create namespace for traffic test in UK West
resource "kubernetes_namespace" "traffic_test_ukwest" {
  provider = kubernetes.ukwest
  metadata {
    name = "traffic-test"
  }
}

# Create traffic test ConfigMap
resource "kubernetes_config_map" "traffic_test_script" {
  provider = kubernetes.uksouth
  metadata {
    name      = "traffic-test-script"
    namespace = kubernetes_namespace.traffic_test_uksouth.metadata[0].name
  }

  data = {
    "test-distribution.sh" = <<-EOF
    #!/bin/bash
    
    # Traffic distribution test script
    FRONT_DOOR_ENDPOINT="${azurerm_cdn_frontdoor_endpoint.endpoint.host_name}"
    TEST_PATH="/traffic-test"
    NUM_REQUESTS=100
    
    echo "Testing traffic distribution between UK South and UK West clusters"
    echo "Front Door Endpoint: $FRONT_DOOR_ENDPOINT"
    echo "Test Path: $TEST_PATH"
    echo "Number of Requests: $NUM_REQUESTS"
    echo ""
    
    # Initialize counters
    uk_south_count=0
    uk_west_count=0
    error_count=0
    
    # Make requests and count responses
    for ((i=1; i<=$NUM_REQUESTS; i++)); do
      # Generate random values for headers
      random_ip="$((RANDOM % 256)).$((RANDOM % 256)).$((RANDOM % 256)).$((RANDOM % 256))"
      random_user_agent="Mozilla/5.0 (Test-$RANDOM)"
      
      # Make request with random headers
      response=$(curl -s \
        -H "Cache-Control: no-cache, no-store, must-revalidate" \
        -H "Pragma: no-cache" \
        -H "X-Forwarded-For: $random_ip" \
        -H "User-Agent: $random_user_agent" \
        "https://$FRONT_DOOR_ENDPOINT$TEST_PATH")
      
      if echo "$response" | grep -q "UK SOUTH"; then
        uk_south_count=$((uk_south_count + 1))
        echo -n "S"
      elif echo "$response" | grep -q "UK WEST"; then
        uk_west_count=$((uk_west_count + 1))
        echo -n "W"
      else
        error_count=$((error_count + 1))
        echo -n "?"
      fi
      
      # Print progress every 10 requests
      if [ $((i % 10)) -eq 0 ]; then
        echo " $i/$NUM_REQUESTS"
      fi
      
      # Small delay to avoid rate limiting
      sleep 0.2
    done
    
    echo ""
    echo ""
    echo "Results:"
    echo "--------"
    echo "UK South: $uk_south_count requests ($$(echo "scale=2; $uk_south_count*100/$NUM_REQUESTS" | bc)%)"
    echo "UK West: $uk_west_count requests ($$(echo "scale=2; $uk_west_count*100/$NUM_REQUESTS" | bc)%)"
    echo "Errors: $error_count requests ($$(echo "scale=2; $error_count*100/$NUM_REQUESTS" | bc)%)"
    echo ""
    EOF
  }
}

# Create test pod to run traffic distribution test
resource "kubernetes_pod" "traffic_test_runner" {
  provider = kubernetes.uksouth
  metadata {
    name      = "traffic-test-runner"
    namespace = kubernetes_namespace.traffic_test_uksouth.metadata[0].name
  }

  spec {
    container {
      name    = "test-runner"
      image   = "curlimages/curl:latest"
      command = ["/bin/sh", "-c", "cp /scripts/test-distribution.sh /tmp && chmod +x /tmp/test-distribution.sh && sleep 3600"]

      volume_mount {
        name       = "test-script"
        mount_path = "/scripts"
      }
    }

    volume {
      name = "test-script"
      config_map {
        name = kubernetes_config_map.traffic_test_script.metadata[0].name
      }
    }
  }
}

# Output instructions for running the test
output "traffic_test_instructions" {
  description = "Instructions for testing traffic distribution"
  value = <<-EOT
    To test the traffic distribution between UK South and UK West clusters:
    
    1. Wait for all resources to be deployed (5-10 minutes)
    
    2. Run the test script with the following command:
       kubectl --kubeconfig ~/.kube/config-uksouth exec -it -n traffic-test traffic-test-runner -- /tmp/test-distribution.sh
    
    3. For a visual test, you can use this command to make 100 requests and see the distribution:
       for i in {1..100}; do 
         curl -s https://${azurerm_cdn_frontdoor_endpoint.endpoint.host_name}/traffic-test | grep -o "UK [A-Z]*" || echo "Error";
         sleep 0.2;
       done | sort | uniq -c
  EOT
}

# ArgoCD Repository Configuration for UK South
resource "kubernetes_manifest" "argocd_repo_uksouth" {
  provider = kubernetes.uksouth
  manifest = {
    apiVersion = "v1"
    kind       = "Secret"
    metadata = {
      name      = "repo-secret"
      namespace = "argocd"
      labels = {
        "argocd.argoproj.io/secret-type" = "repository"
      }
    }
    stringData = {
      type     = "git"
      url      = var.git_repository_url
      username = var.git_username
      password = data.azurerm_key_vault_secret.git_pat_token.value
    }
  }
  depends_on = [
    kubernetes_namespace.argocd_uksouth,
    azurerm_kubernetes_cluster.uksouth,
    data.azurerm_key_vault_secret.git_pat_token,
    helm_release.argocd_uksouth
  ]
}

# ArgoCD Repository Configuration for UK West
resource "kubernetes_manifest" "argocd_repo_ukwest" {
  provider = kubernetes.ukwest
  manifest = {
    apiVersion = "v1"
    kind       = "Secret"
    metadata = {
      name      = "repo-secret"
      namespace = "argocd"
      labels = {
        "argocd.argoproj.io/secret-type" = "repository"
      }
    }
    stringData = {
      type     = "git"
      url      = var.git_repository_url
      username = var.git_username
      password = data.azurerm_key_vault_secret.git_pat_token.value
    }
  }
  depends_on = [
    kubernetes_namespace.argocd_ukwest,
    azurerm_kubernetes_cluster.ukwest,
    data.azurerm_key_vault_secret.git_pat_token,
    helm_release.argocd_ukwest
  ]
}

# ArgoCD Project Configuration for UK South
resource "kubectl_manifest" "argocd_project_uksouth" {
  provider = kubectl.uksouth
  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"
    metadata = {
      name      = "istio-system"
      namespace = "argocd"
    }
    spec = {
      description = "Project for Istio components"
      sourceRepos = [var.git_repository_url]
      destinations = [
        {
          namespace = "istio-system"
          server    = "https://kubernetes.default.svc"
        }
      ]
      clusterResourceWhitelist = [
        {
          group = "*"
          kind  = "*"
        }
      ]
    }
  })
  depends_on = [
    kubernetes_manifest.argocd_repo_uksouth,
    helm_release.argocd_uksouth
  ]
}

# ArgoCD Project Configuration for UK West
resource "kubectl_manifest" "argocd_project_ukwest" {
  provider = kubectl.ukwest
  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"
    metadata = {
      name      = "istio-system"
      namespace = "argocd"
    }
    spec = {
      description = "Project for Istio components"
      sourceRepos = [var.git_repository_url]
      destinations = [
        {
          namespace = "istio-system"
          server    = "https://kubernetes.default.svc"
        }
      ]
      clusterResourceWhitelist = [
        {
          group = "*"
          kind  = "*"
        }
      ]
    }
  })
  depends_on = [
    kubernetes_manifest.argocd_repo_ukwest,
    helm_release.argocd_ukwest
  ]
}

# Apply ApplicationSets for Istio components
resource "kubectl_manifest" "istio_applicationsets" {
  provider = kubectl.uksouth
  for_each = {
    base    = file("${path.module}/../applicationsets/istio-base.yaml")
    istiod  = file("${path.module}/../applicationsets/istiod.yaml")
    gateway = file("${path.module}/../applicationsets/gateway.yaml")
  }

  yaml_body = each.value

  depends_on = [
    kubectl_manifest.argocd_project_uksouth,
    kubectl_manifest.argocd_project_ukwest,
    kubernetes_manifest.argocd_repo_uksouth,
    kubernetes_manifest.argocd_repo_ukwest
  ]
} 