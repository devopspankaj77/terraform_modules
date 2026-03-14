variable "name" {
  description = "Name of the container registry (alphanumeric only, 5-50 chars)"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "sku" {
  description = "SKU: Basic, Standard, or Premium"
  type        = string
  default     = "Basic"
}

variable "admin_enabled" {
  description = "Enable admin user"
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Allow public network access"
  type        = bool
  default     = true
}

variable "georeplication_locations" {
  description = "Replication locations (Premium SKU only)"
  type        = list(string)
  default     = []
}

variable "tags" {
  type        = map(string)
  default     = {}
}
