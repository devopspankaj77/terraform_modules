# Naming conventions and locals for resource naming
# Used across environments for consistent naming

locals {
  # Environment short names for resource naming
  env_short = {
    dev  = "dev"
    uat  = "uat"
    prod = "prd"
  }

  # Naming prefix: e.g. "myorg-dev" or "myorg-prd"
  name_prefix = "${var.organization_name}-${local.env_short[var.environment]}"

  # Common naming pattern for resources
  # Usage: "${local.name_prefix}-<resource-type>-<suffix>"
  resource_naming = {
    vnet             = "${local.name_prefix}-vnet"
    vm               = "${local.name_prefix}-vm"
    storage_account  = "${local.name_prefix}stg"  # Storage accounts: alphanumeric only, 3-24 chars
    sql_server       = "${local.name_prefix}-sql"
    keyvault         = "${local.name_prefix}-kv"
    aks              = "${local.name_prefix}-aks"
  }
}

variable "organization_name" {
  description = "Organization or project name used in resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, uat, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "uat", "prod"], var.environment)
    error_message = "Environment must be one of: dev, uat, prod."
  }
}
