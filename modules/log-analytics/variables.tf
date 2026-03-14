variable "name" {
  description = "Name of the Log Analytics workspace"
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
  description = "SKU: PerGB2018 or Free"
  type        = string
  default     = "PerGB2018"
}

variable "retention_in_days" {
  description = "Retention in days (30 to 730)"
  type        = number
  default     = 30
}

variable "tags" {
  type    = map(string)
  default = {}
}
