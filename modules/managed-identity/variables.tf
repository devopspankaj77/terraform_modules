variable "name" {
  description = "Name of the user-assigned managed identity"
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

variable "tags" {
  type    = map(string)
  default = {}
}
