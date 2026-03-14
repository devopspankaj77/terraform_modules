variable "zone_name" {
  description = "Private DNS zone name (e.g. privatelink.database.windows.net, privatelink.azurecr.io)"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "virtual_network_ids" {
  description = "List of VNet IDs to link to this zone"
  type        = list(string)
  default     = []
}

variable "registration_enabled" {
  description = "Enable auto-registration of VMs in the zone"
  type        = bool
  default     = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
