# Logic App (Standard) Module
# Requires App Service Plan and Storage Account

resource "azurerm_logic_app_standard" "main" {
  name                       = var.name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  app_service_plan_id        = var.app_service_plan_id
  storage_account_name      = var.storage_account_name
  storage_account_access_key = var.storage_account_access_key
  tags                       = var.tags

  app_settings = var.app_settings

  site_config {
    ftps_state = "Disabled"
  }
}
