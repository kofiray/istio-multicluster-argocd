resource "azurerm_resource_group" "aks_rg" {
  name     = var.aks_resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_kubernetes_cluster" "uksouth" {
  name                = "aks-uksouth"
  location            = "UK South"
  resource_group_name = azurerm_resource_group.aks_rg.name
  dns_prefix         = "aks-uksouth"
  kubernetes_version = var.kubernetes_version

  default_node_pool {
    name            = "default"
    node_count      = var.node_count
    vm_size         = var.vm_size
    os_disk_size_gb = 50
    zones           = ["1", "2", "3"]
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin     = "azure"
    load_balancer_sku = "standard"
    network_policy    = "calico"
  }

  tags = var.tags
}

resource "azurerm_kubernetes_cluster" "ukwest" {
  name                = "aks-ukwest"
  location            = "UK West"
  resource_group_name = azurerm_resource_group.aks_rg.name
  dns_prefix         = "aks-ukwest"
  kubernetes_version = var.kubernetes_version

  default_node_pool {
    name            = "default"
    node_count      = var.node_count
    vm_size         = var.vm_size
    os_disk_size_gb = 50
    zones           = ["1", "2", "3"]
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin     = "azure"
    load_balancer_sku = "standard"
    network_policy    = "calico"
  }

  tags = var.tags
}

# Create node pools for Istio Gateway
resource "azurerm_kubernetes_cluster_node_pool" "uksouth_gateway" {
  name                  = "gateway"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.uksouth.id
  vm_size              = var.gateway_vm_size
  node_count           = var.gateway_node_count
  zones                = ["1", "2", "3"]

  node_labels = {
    "purpose" = "istio-gateway"
  }

  node_taints = [
    "purpose=istio-gateway:NoSchedule"
  ]

  tags = var.tags
}

resource "azurerm_kubernetes_cluster_node_pool" "ukwest_gateway" {
  name                  = "gateway"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.ukwest.id
  vm_size              = var.gateway_vm_size
  node_count           = var.gateway_node_count
  zones                = ["1", "2", "3"]

  node_labels = {
    "purpose" = "istio-gateway"
  }

  node_taints = [
    "purpose=istio-gateway:NoSchedule"
  ]

  tags = var.tags
}

# Output the cluster credentials
output "uksouth_kube_config" {
  value     = azurerm_kubernetes_cluster.uksouth.kube_config_raw
  sensitive = true
}

output "ukwest_kube_config" {
  value     = azurerm_kubernetes_cluster.ukwest.kube_config_raw
  sensitive = true
} 