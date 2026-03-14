variable "server_name" {
  description = "Name of the SQL server"
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

variable "sql_version" {
  description = "SQL Server version (e.g. 12.0)"
  type        = string
  default     = "12.0"
}

variable "admin_username" {
  description = "SQL admin username"
  type        = string
}

variable "admin_password" {
  description = "SQL admin password"
  type        = string
  sensitive   = true
}

variable "min_tls_version" {
  description = "Minimum TLS version"
  type        = string
  default     = "1.2"
}

variable "firewall_rules" {
  description = "Map of firewall rule names to { start_ip_address, end_ip_address }"
  type        = map(object({
    start_ip_address = string
    end_ip_address   = string
  }))
  default = {}
}

variable "databases" {
  description = "Map of database names to configuration"
  type = map(object({
    collation      = optional(string, "SQL_Latin1_General_CP1_CI_AS")
    license_type   = optional(string, "LicenseIncluded")
    max_size_gb    = optional(number, 32)
    sku_name       = optional(string, "Basic")
    zone_redundant = optional(bool, false)
    short_term_retention_days = optional(number, null) # Optional: 7–35 for PITR; set in tfvars
  }))
  default = {}
}

# Optional: security baseline – Azure AD admin (RESOURCE_CONTROLS_SHEET). Set in tfvars.
variable "azuread_administrator" {
  description = "Optional Azure AD admin: login (e.g. Azure AD group name), object_id, tenant_id (optional)."
  type = object({
    login     = string
    object_id = string
    tenant_id  = optional(string, null)
  })
  default = null
}

# Optional: extended auditing to storage or Log Analytics. Set in tfvars.
variable "extended_auditing_policy" {
  description = "Optional extended auditing: storage_endpoint and/or log_analytics_workspace_id."
  type = object({
    storage_endpoint              = optional(string, null)
    storage_account_access_key    = optional(string, null)
    storage_account_access_key_is_secondary = optional(bool, false)
    log_analytics_workspace_id    = optional(string, null)
    log_analytics_workspace_key   = optional(string, null)
    retention_in_days             = optional(number, null)
  })
  default = null
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
