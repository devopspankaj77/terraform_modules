variable "name" {
  description = "Name of the function app"
  type        = string
}

variable "plan_name" {
  description = "Name of the App Service Plan (consumption or dedicated)"
  type        = string
}

variable "location" {
  type        = string
}

variable "resource_group_name" {
  type        = string
}

variable "sku_name" {
  description = "Y1 (consumption), EP1, P1v2, etc."
  type        = string
  default     = "Y1"
}

variable "storage_account_name" {
  description = "Name for the storage account (when not using existing)"
  type        = string
  default     = null
}

variable "existing_storage_account_name" {
  description = "Use existing storage account"
  type        = string
  default     = null
}

variable "existing_storage_account_access_key" {
  description = "Access key when using existing storage account"
  type        = string
  default     = null
  sensitive   = true
}

variable "node_version" {
  type    = string
  default = null
}

variable "python_version" {
  type    = string
  default = null
}

variable "dotnet_version" {
  type    = string
  default = null
}

variable "java_version" {
  type    = string
  default = null
}

variable "app_settings" {
  type        = map(string)
  default     = {}
}

variable "tags" {
  type        = map(string)
  default     = {}
}
