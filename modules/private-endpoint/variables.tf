variable "name" {
  description = "Name of the private endpoint"
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
  description = "Subnet ID for the private endpoint (must have private endpoint network policies disabled)"
  type        = string
}

variable "target_resource_id" {
  description = "ID of the resource to connect (e.g. storage account, key vault, SQL server)"
  type        = string
}

variable "subresource_name" {
  description = "Subresource name (e.g. blob, file, vault, sqlServer)"
  type        = string
}

variable "private_dns_zone_id" {
  description = "Optional Private DNS zone ID for private link FQDN resolution"
  type        = string
  default     = null
}

variable "tags" {
  type        = map(string)
  default     = {}
}
