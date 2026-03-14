variable "name" {
  description = "Name of the storage account (3-24 chars, alphanumeric only)"
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

variable "account_tier" {
  description = "Storage account tier (Standard or Premium)"
  type        = string
  default     = "Standard"
}

variable "replication_type" {
  description = "Replication type (LRS, GRS, RAGRS, ZRS)"
  type        = string
  default     = "LRS"
}

variable "account_kind" {
  description = "Account kind (StorageV2, BlobStorage, etc.)"
  type        = string
  default     = "StorageV2"
}

variable "min_tls_version" {
  description = "Minimum TLS version"
  type        = string
  default     = "TLS1_2"
}

variable "enable_blob_versioning" {
  description = "Enable blob versioning"
  type        = bool
  default     = false
}

variable "containers" {
  description = "Map of container names to access_type (private, blob, container)"
  type        = map(object({
    access_type = string
  }))
  default = {}
}

# Optional: security baseline – soft delete (RESOURCE_CONTROLS_SHEET). Set in tfvars (e.g. 7 dev, 30 prod).
variable "blob_soft_delete_retention_days" {
  description = "Blob soft delete retention in days. Set to 7–30 in tfvars to enable."
  type        = number
  default     = null
}

variable "container_soft_delete_retention_days" {
  description = "Container soft delete retention in days. Set to 7–30 in tfvars to enable."
  type        = number
  default     = null
}

# Optional: prefer AAD auth; set true when using managed identity only.
variable "shared_key_access_disabled" {
  description = "Disable shared key (access key) auth; use AAD only. Enable via tfvars for prod."
  type        = bool
  default     = false
}

# Optional: network rules (deny by default, allow selected). Pass from tfvars when not using PE only.
variable "network_rules" {
  description = "Optional network rules: default_action (Deny|Allow), bypass list, ip_rules list, subnet_ids list."
  type = object({
    default_action               = optional(string, "Deny")
    bypass                       = optional(list(string), ["AzureServices"])
    ip_rules                     = optional(list(string), [])
    virtual_network_subnet_ids   = optional(list(string), [])
  })
  default = null
}

# Optional: management lock on storage account.
variable "create_delete_lock" {
  description = "Create CanNotDelete lock on storage account. Enable via tfvars for prod."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
