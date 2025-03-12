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
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
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