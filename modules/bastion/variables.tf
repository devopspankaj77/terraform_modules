variable "name" {
  description = "Name of the Bastion Host"
  type        = string
}

variable "public_ip_name" {
  description = "Name of the Public IP for Bastion"
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

variable "subnet_id" {
  description = "Subnet ID for Azure Bastion (must be AzureBastionSubnet)"
  type        = string
}

variable "sku" {
  description = "Bastion SKU"
  type        = string
  default     = "Standard"
}

variable "scale_units" {
  description = "Bastion scale units (Standard SKU only)"
  type        = number
  default     = 2
}

variable "copy_paste_enabled" {
  description = "Enable copy/paste in Bastion session"
  type        = bool
  default     = true
}

variable "file_copy_enabled" {
  description = "Enable file copy for Bastion (Standard SKU)"
  type        = bool
  default     = false
}

variable "tunneling_enabled" {
  description = "Enable native client tunneling (Standard SKU)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}

