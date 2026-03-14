# Application Insights Module
# App telemetry for App Service, Function App, APIs

resource "azurerm_application_insights" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = var.application_type
  workspace_id         = var.workspace_id
  tags                = var.tags
}
