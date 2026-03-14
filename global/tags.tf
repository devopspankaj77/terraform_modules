# Default tags applied to all resources
# Centralize tag management for consistency and cost management

locals {
  default_tags = {
    Environment        = var.environment
    Project            = var.project_name
    Owner              = var.owner
    "Created By"       = var.created_by
    "Created Date"     = formatdate("YYYY-MM-DD", timestamp())
    Requester          = var.requester
    "Ticket Reference" = var.ticket_reference
  }
}

  # Merge custom tags with default tags (custom takes precedence)
  common_tags = merge(local.default_tags, var.additional_tags)
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
}

variable "owner" {
  description = "Owner or team responsible for the resources"
  type        = string
}

variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "created_by" {
  description = "resource creater name for tagging"
  type        = string
} 

variable "var.created_date" {
  description = "resource created_date for tagging"
  type        = string
} 