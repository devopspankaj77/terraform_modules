variable "principal_id" {
  description = "Object ID of user / group / managed identity"
  type        = string
}

variable "role_name" {
  description = "Azure built-in role name"
  type        = string
}

variable "scope" {
  description = "Scope at which role will be assigned"
  type        = string
}