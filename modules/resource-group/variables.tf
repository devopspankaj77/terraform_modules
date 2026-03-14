variable "name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}

# Optional: security baseline – delete lock (RESOURCE_CONTROLS_SHEET)
variable "create_lock" {
  description = "Create a CanNotDelete management lock on the resource group. Enable via tfvars for prod."
  type        = bool
  default     = false
}

variable "lock_level" {
  description = "Lock level when create_lock is true: CanNotDelete or ReadOnly"
  type        = string
  default     = "CanNotDelete"
}
