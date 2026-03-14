# UAT environment — resources defined here; add or remove module blocks as needed.

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = { source = "hashicorp/azurerm"; version = "~> 3.0" }
  }
}

provider "azurerm" {
  features {}
}

locals {
  name_prefix       = "${var.organization_name}-${var.environment}"
  name_prefix_short = replace(local.name_prefix, "-", "")
  common_tags = merge({
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
    Owner       = var.owner
  }, var.additional_tags)
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

module "vnet" {
  source = "../../modules/vnet"

  name                           = "${local.name_prefix}-vnet"
  location                       = azurerm_resource_group.main.location
  resource_group_name            = azurerm_resource_group.main.name
  address_space                  = var.vnet_address_space
  subnets                        = var.vnet_subnets
  create_nsg                     = var.vnet_create_nsg
  nsg_per_subnet                 = var.vnet_nsg_per_subnet
  nsg_rules                      = var.vnet_nsg_rules
  create_private_endpoint_subnet = var.vnet_create_private_endpoint_subnet
  private_endpoint_subnet_name   = var.vnet_private_endpoint_subnet_name
  private_endpoint_subnet_prefix = var.vnet_private_endpoint_subnet_prefix
  tags                           = local.common_tags
}

module "storage_account" {
  source = "../../modules/storage-account"

  name                     = "${local.name_prefix_short}stg"
  location                 = azurerm_resource_group.main.location
  resource_group_name      = azurerm_resource_group.main.name
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication_type
  tags                     = local.common_tags
}

module "keyvault" {
  source = "../../modules/keyvault"

  name                = "${local.name_prefix}-kv"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

module "app_service" {
  source = "../../modules/app-service"

  name                = "${local.name_prefix}-app"
  plan_name           = "${local.name_prefix}-asp"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = var.app_service_os_type
  sku_name            = var.app_service_sku_name
  app_settings        = var.app_service_app_settings
  tags                = local.common_tags
}

module "redis" {
  source = "../../modules/redis"

  name                = "${local.name_prefix}-redis"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  capacity            = var.redis_capacity
  family              = var.redis_family
  sku_name            = var.redis_sku_name
  tags                = local.common_tags
}
