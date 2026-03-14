# Recovery Services Vault Module
# For VM backup, Azure Backup

resource "azurerm_recovery_services_vault" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  soft_delete_enabled = var.soft_delete_enabled
  tags                = var.tags
}

# Optional: management lock (enable via create_delete_lock = true in tfvars)
resource "azurerm_management_lock" "main" {
  for_each = var.create_delete_lock ? toset(["lock"]) : toset([])

  name       = "${var.name}-lock"
  scope      = azurerm_recovery_services_vault.main.id
  lock_level = "CanNotDelete"
}
