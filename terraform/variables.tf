variable "aks_resource_group_name" {
  description = "Name of the resource group for AKS clusters"
  type        = string
}

variable "kubernetes_version" {
  description = "Version of Kubernetes to use for AKS clusters"
  type        = string
  default     = "1.27.3"
}

variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 3
}

variable "vm_size" {
  description = "Size of VMs in the default node pool"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "gateway_vm_size" {
  description = "Size of VMs in the gateway node pool"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "gateway_node_count" {
  description = "Number of nodes in the gateway node pool"
  type        = number
  default     = 2
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "UK South"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Production"
    Project     = "Istio-MultiCluster"
    ManagedBy   = "Terraform"
  }
}

variable "frontdoor_profile_name" {
  description = "Name of the Front Door profile"
  type        = string
}

variable "frontdoor_sku_name" {
  description = "SKU name for Front Door"
  type        = string
  default     = "Standard_AzureFrontDoor"
}

variable "frontdoor_endpoint_name" {
  description = "Name of the Front Door endpoint"
  type        = string
}

variable "frontdoor_origin_group_name" {
  description = "Name of the Front Door origin group"
  type        = string
}

variable "frontdoor_origin_name_uksouth" {
  description = "Name of the UK South origin"
  type        = string
}

variable "frontdoor_origin_name_ukwest" {
  description = "Name of the UK West origin"
  type        = string
}

variable "frontdoor_route_name" {
  description = "Name of the Front Door route"
  type        = string
}

variable "app_hostname" {
  description = "Hostname for the application"
  type        = string
}

variable "uksouth_kubeconfig_path" {
  description = "Path to the kubeconfig file for UK South cluster"
  type        = string
}

variable "ukwest_kubeconfig_path" {
  description = "Path to the kubeconfig file for UK West cluster"
  type        = string
}

variable "git_repository_url" {
  description = "URL of the Git repository for ArgoCD"
  type        = string
}

variable "git_username" {
  description = "Username for Git repository authentication"
  type        = string
}

variable "argocd_helm_version" {
  description = "Version of the ArgoCD Helm chart to install"
  type        = string
  default     = "5.51.6"
} 