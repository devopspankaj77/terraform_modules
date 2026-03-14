variable "name" {
  description = "Name of the MySQL flexible server"
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

variable "mysql_version" {
  description = "MySQL version (e.g. 8.0.21)"
  type        = string
  default     = "8.0.21"
}

variable "sku_name" {
  description = "SKU (e.g. GP_Standard_D2ds_v4)"
  type        = string
  default     = "GP_Standard_D2ds_v4"
}

variable "zone" {
  description = "Availability zone (1, 2, 3 or null)"
  type        = string
  default     = null
}

variable "administrator_login" {
  description = "Admin username"
  type        = string
}

variable "administrator_password" {
  description = "Admin password"
  type        = string
  sensitive   = true
}

variable "storage_size_gb" {
  type    = number
  default = 20
}

variable "storage_iops" {
  type    = number
  default = null
}

variable "storage_auto_grow_enabled" {
  type    = bool
  default = true
}

variable "backup_retention_days" {
  type    = number
  default = 7
}

variable "geo_redundant_backup_enabled" {
  type    = bool
  default = false
}

variable "high_availability_mode" {
  description = "SameZone, ZoneRedundant, or null/Disabled to disable"
  type        = string
  default     = null
}

variable "maintenance_window" {
  type = object({
    day_of_week  = number
    start_hour   = number
    start_minute = number
  })
  default = null
}

variable "databases" {
  description = "Map of database names to optional charset/collation"
  type        = map(any)
  default     = {}
}

variable "firewall_rules" {
  type = map(object({
    start_ip_address = string
    end_ip_address   = string
  }))
  default = {}
}

variable "tags" {
  type        = map(string)
  default     = {}
}
