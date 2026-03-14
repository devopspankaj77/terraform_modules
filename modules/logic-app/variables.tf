variable "name" {
  description = "Name of the Logic App (Standard)"
  type        = string
}

variable "location" {
  type        = string
}

variable "resource_group_name" {
  type        = string
}

variable "app_service_plan_id" {
  description = "ID of the App Service Plan (dedicated, not consumption)"
  type        = string
}

variable "storage_account_name" {
  type        = string
}

variable "storage_account_access_key" {
  type        = string
  sensitive   = true
}

variable "app_settings" {
  type        = map(string)
  default     = {}
}

variable "tags" {
  type        = map(string)
  default     = {}
}
