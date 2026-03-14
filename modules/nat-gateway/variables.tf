variable "name" {
  description = "Name of the NAT gateway"
  type        = string
}

variable "public_ip_name" {
  description = "Name of the public IP for the NAT gateway"
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

variable "sku_name" {
  description = "SKU: Standard"
  type        = string
  default     = "Standard"
}

variable "idle_timeout_in_minutes" {
  description = "Idle timeout in minutes"
  type        = number
  default     = 10
}

variable "tags" {
  type    = map(string)
  default = {}
}
