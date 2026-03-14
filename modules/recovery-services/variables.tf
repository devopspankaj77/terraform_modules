variable "name" {
  description = "Name of the Recovery Services vault"
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
  description = "SKU: Standard or RS0"
  type        = string
  default     = "Standard"
}

variable "soft_delete_enabled" {
  description = "Enable soft delete"
  type        = bool
  default     = true
}

# Optional: management lock (RESOURCE_CONTROLS_SHEET). Set true in tfvars for prod.
variable "create_delete_lock" {
  description = "Create CanNotDelete lock on Recovery Services vault."
  type        = bool
  default     = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
