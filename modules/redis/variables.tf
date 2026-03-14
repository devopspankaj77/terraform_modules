variable "name" {
  description = "Name of the Redis cache (alphanumeric and hyphens)"
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

variable "capacity" {
  description = "Redis size (0, 1, 2, 3, 4, 5 for Basic/Standard; 1-6 for Premium)"
  type        = number
  default     = 0
}

variable "family" {
  description = "Family: C (Basic/Standard) or P (Premium)"
  type        = string
  default     = "C"
}

variable "sku_name" {
  description = "SKU: Basic, Standard, or Premium"
  type        = string
  default     = "Basic"
}

variable "non_ssl_port_enabled" {
  description = "Enable non-SSL port (6379); prefer false for security."
  type        = bool
  default     = false
}

variable "minimum_tls_version" {
  description = "Minimum TLS version (1.0, 1.1, 1.2)"
  type        = string
  default     = "1.2"
}

variable "maxmemory_policy" {
  description = "Max memory policy (e.g. volatile-lru)"
  type        = string
  default     = "volatile-lru"
}

variable "patch_schedule" {
  description = "Patch schedule { day_of_week, start_hour_utc }"
  type = object({
    day_of_week    = string
    start_hour_utc = number
  })
  default = null
}

variable "tags" {
  type        = map(string)
  default     = {}
}
