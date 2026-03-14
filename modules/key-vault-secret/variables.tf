variable "secret_name" {
  description = "Name of the secret in Key Vault"
  type        = string
}

variable "secret_value" {
  description = "Value of the secret"
  type        = string
  sensitive   = true
}

variable "key_vault_id" {
  description = "ID of the existing Key Vault"
  type        = string
}

variable "content_type" {
  description = "Optional content type"
  type        = string
  default     = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
