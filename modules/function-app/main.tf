# Function App Module (Azure Functions)

resource "azurerm_service_plan" "main" {
  name                = var.plan_name
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = var.sku_name
  tags                = var.tags
}

resource "azurerm_storage_account" "main" {
  for_each = var.existing_storage_account_name == null ? toset(["stg"]) : toset([])

  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags
}

resource "azurerm_linux_function_app" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.main.id
  storage_account_name       = var.existing_storage_account_name != null ? var.existing_storage_account_name : azurerm_storage_account.main["stg"].name
  storage_account_access_key = var.existing_storage_account_name != null ? var.existing_storage_account_access_key : azurerm_storage_account.main["stg"].primary_access_key
  tags                = var.tags

  site_config {
    application_stack {
      node_version   = var.node_version
      python_version = var.python_version
      dotnet_version = coalesce(var.dotnet_version, "6.0")
      java_version   = var.java_version
    }
    ftps_state = "Disabled"
  }

  app_settings = var.app_settings
}
