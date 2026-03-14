variable "name" {
  description = "Name of the web app"
  type        = string
}

variable "plan_name" {
  description = "Name of the App Service Plan"
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

variable "os_type" {
  description = "OS type: Linux or Windows"
  type        = string
  default     = "Linux"
}

variable "sku_name" {
  description = "SKU (e.g. B1, P1v2, F1)"
  type        = string
  default     = "B1"
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
  default     = null
}

variable "app_settings" {
  description = "App settings key-value map"
  type        = map(string)
  default     = {}
}

variable "connection_strings" {
  description = "Connection strings (name => { type, value })"
  type = map(object({
    type  = string
    value = string
  }))
  default = {}
}

# Optional: security baseline (RESOURCE_CONTROLS_SHEET). Set in tfvars.
variable "https_only" {
  description = "Accept HTTPS only. Set true in tfvars for prod."
  type        = bool
  default     = true
}

variable "client_certificate_enabled" {
  description = "Require client certificates for incoming requests (mutual TLS)."
  type        = bool
  default     = false
}

variable "always_on" {
  description = "Always On (override SKU default). Set true for prod when SKU supports it."
  type        = bool
  default     = null
}

variable "identity_enabled" {
  description = "Enable system-assigned managed identity for the web app."
  type        = bool
  default     = true
}

variable "tags" {
  type        = map(string)
  default     = {}
}
