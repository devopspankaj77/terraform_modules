# App Service Module
# Creates App Service Plan and App Service (Web App)

resource "azurerm_service_plan" "main" {
  name                = var.plan_name
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = var.os_type
  sku_name            = var.sku_name
  tags                = var.tags
}

resource "azurerm_linux_web_app" "main" {
  for_each = var.os_type == "Linux" ? toset(["Linux"]) : toset([])

  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.main.id
  https_only          = var.https_only
  tags                = var.tags

  dynamic "identity" {
    for_each = var.identity_enabled ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }

  site_config {
    always_on               = var.always_on != null ? var.always_on : (var.sku_name == "F1" || var.sku_name == "B1" ? false : true)
    ftps_state              = "Disabled"
    health_check_path       = var.health_check_path
    # client_certificate_*: set when provider supports site_config.client_certificate_mode; variable retained for tfvars
  }

  app_settings = var.app_settings

  dynamic "connection_string" {
    for_each = var.connection_strings
    content {
      name  = connection_string.key
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }
}

resource "azurerm_windows_web_app" "main" {
  for_each = var.os_type == "Windows" ? toset(["Windows"]) : toset([])

  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.main.id
  https_only          = var.https_only
  tags                = var.tags

  dynamic "identity" {
    for_each = var.identity_enabled ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }

  site_config {
    always_on               = var.always_on != null ? var.always_on : (var.sku_name == "F1" || var.sku_name == "B1" ? false : true)
    ftps_state              = "Disabled"
    health_check_path       = var.health_check_path
    # client_certificate_*: set when provider supports site_config.client_certificate_mode; variable retained for tfvars
  }

  app_settings = var.app_settings

  dynamic "connection_string" {
    for_each = var.connection_strings
    content {
      name  = connection_string.key
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }
}
