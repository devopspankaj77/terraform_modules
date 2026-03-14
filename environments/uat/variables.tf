# UAT — only configuration for resources used in main.tf

variable "environment" {
  type = string
}

variable "organization_name" {
  type = string
}

variable "project_name" {
  type = string
}

variable "owner" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "additional_tags" {
  type    = map(string)
  default = {}
}

# VNet
variable "vnet_address_space" {
  type    = list(string)
  default = ["10.1.0.0/16"]
}

variable "vnet_subnets" {
  type = map(object({
    address_prefixes = list(string)
  }))
  default = {
    default = { address_prefixes = ["10.1.1.0/24"] }
    aks     = { address_prefixes = ["10.1.2.0/24"] }
  }
}

variable "vnet_create_nsg" {
  type    = bool
  default = true
}

variable "vnet_nsg_per_subnet" {
  type    = bool
  default = false
}

variable "vnet_nsg_rules" {
  type    = map(any)
  default = {}
}

variable "vnet_create_private_endpoint_subnet" {
  type    = bool
  default = false
}

variable "vnet_private_endpoint_subnet_name" {
  type    = string
  default = "private-endpoints"
}

variable "vnet_private_endpoint_subnet_prefix" {
  type    = string
  default = "10.1.100.0/24"
}

# Storage
variable "storage_account_tier" {
  type    = string
  default = "Standard"
}

variable "storage_account_replication_type" {
  type    = string
  default = "LRS"
}

# App Service
variable "app_service_os_type" {
  type    = string
  default = "Linux"
}

variable "app_service_sku_name" {
  type    = string
  default = "B1"
}

variable "app_service_app_settings" {
  type    = map(string)
  default = {}
}

# Redis
variable "redis_capacity" {
  type    = number
  default = 0
}

variable "redis_family" {
  type    = string
  default = "C"
}

variable "redis_sku_name" {
  type    = string
  default = "Basic"
}
