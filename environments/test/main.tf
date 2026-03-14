##################################
# Common Tags
##################################

locals {
  common_tags = merge({
    "Created By"       = var.created_by
    "Created Date"     = formatdate("YYYY-MM-DD", timestamp())
    "Environment"      = var.environment
    "Requester"        = var.requester
    "Ticket Reference" = var.ticket_reference
    "Project Name"     = var.project_name
    "ManagedBy"        = "Terraform"
  }, var.additional_tags)
}

##################################
# Resource Group
##################################

module "rg" {
  source   = "../../modules/resource-group"
  name     = var.rg.name
  location = var.rg.location
  tags     = local.common_tags
}
