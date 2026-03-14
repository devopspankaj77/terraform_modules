variable "name" {
  description = "Name of the Application Insights resource"
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

variable "application_type" {
  description = "Type: web, other"
  type        = string
  default     = "web"
}

variable "workspace_id" {
  description = "Log Analytics workspace ID (optional, for workspace-based App Insights)"
  type        = string
  default     = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
