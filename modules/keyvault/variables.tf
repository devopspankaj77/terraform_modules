variable "name" {
  description = "Name of the Key Vault (3-24 chars, alphanumeric and hyphens)"
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
  description = "SKU name (standard or premium)"
  type        = string
  default     = "standard"
}

variable "soft_delete_retention_days" {
  description = "Soft delete retention in days"
  type        = number
  default     = 7
}

variable "purge_protection_enabled" {
  description = "Enable purge protection"
  type        = bool
  default     = false
}

variable "rbac_authorization_enabled" {
  description = "Use RBAC for authorization instead of access policies"
  type        = bool
  default     = false
}



variable "access_policies_current_secret_permissions" {
  description = "Secret permissions for current client (when not using RBAC)"
  type        = list(string)
  default     = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"]
}

variable "access_policies_current_key_permissions" {
  description = "Key permissions for current client (when not using RBAC)"
  type        = list(string)
  default     = ["Get", "List", "Create", "Delete", "Recover", "Backup", "Restore"]
}

variable "additional_access_policies" {
  description = "Additional access policies (object_id, tenant_id, secret_permissions, key_permissions)"
  type = map(object({
    tenant_id          = string
    object_id          = string
    secret_permissions = list(string)
    key_permissions    = list(string)
  }))
  default = {}
}

# Optional: security baseline – network ACLs when not PE-only (RESOURCE_CONTROLS_SHEET). Pass from tfvars.
variable "network_acls" {
  description = "Optional network ACLs: default_action (Allow|Deny), bypass list, ip_rules, virtual_network_subnet_ids."
  type = object({
    default_action             = optional(string, "Deny")
    bypass                     = optional(string, "AzureServices")
    ip_rules                   = optional(list(string), [])
    virtual_network_subnet_ids = optional(list(string), [])
  })
  default = null
}

# Optional: management lock on Key Vault.
variable "create_delete_lock" {
  description = "Create CanNotDelete lock on Key Vault. Enable via tfvars for prod."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
