# Key Vault Module
# Creates Azure Key Vault with optional access policies

# Key Vault Module (RBAC Only)
# Uses Azure RBAC instead of access policies

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                        = var.name
  location                    = var.location
  resource_group_name         = var.resource_group_name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = var.sku_name
  soft_delete_retention_days  = var.soft_delete_retention_days
  purge_protection_enabled    = var.purge_protection_enabled
  tags                        = var.tags
  public_network_access_enabled = false
  rbac_authorization_enabled  = var.rbac_authorization_enabled

  dynamic "network_acls" {
    for_each = var.network_acls != null ? [var.network_acls] : []
    content {
      default_action             = network_acls.value.default_action
      bypass                     = network_acls.value.bypass
      ip_rules                   = network_acls.value.ip_rules
      virtual_network_subnet_ids = network_acls.value.virtual_network_subnet_ids
    }
  }
}

# Optional: management lock (enable via create_delete_lock = true in tfvars)
resource "azurerm_management_lock" "main" {
  for_each = var.create_delete_lock ? toset(["lock"]) : toset([])

  name       = "${var.name}-lock"
  scope      = azurerm_key_vault.main.id
  lock_level = "CanNotDelete"
}

