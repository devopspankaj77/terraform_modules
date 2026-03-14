# User-Assigned Managed Identity Module
# For apps, AKS, Function App to access Key Vault, Storage, etc. without keys

resource "azurerm_user_assigned_identity" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}
