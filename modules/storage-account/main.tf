# Storage Account Module
# Creates Azure Storage Account with optional containers and security baseline options

resource "azurerm_storage_account" "main" {
  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  account_tier                  = var.account_tier
  account_replication_type      = var.replication_type
  account_kind                  = var.account_kind
  tags                          = var.tags
  public_network_access_enabled = false
  min_tls_version               = var.min_tls_version
  https_traffic_only_enabled    = true
  # shared_key_access_enabled: set via Azure Portal/Policy or when provider supports it (variable retained for tfvars)

  dynamic "blob_properties" {
    for_each = var.enable_blob_versioning || var.blob_soft_delete_retention_days != null || var.container_soft_delete_retention_days != null ? [1] : []
    content {
      versioning_enabled = var.enable_blob_versioning
      dynamic "delete_retention_policy" {
        for_each = var.blob_soft_delete_retention_days != null ? [1] : []
        content {
          days = var.blob_soft_delete_retention_days
        }
      }
      dynamic "container_delete_retention_policy" {
        for_each = var.container_soft_delete_retention_days != null ? [1] : []
        content {
          days = var.container_soft_delete_retention_days
        }
      }
    }
  }

  dynamic "network_rules" {
    for_each = var.network_rules != null ? [var.network_rules] : []
    content {
      default_action             = network_rules.value.default_action
      bypass                     = network_rules.value.bypass
      ip_rules                   = network_rules.value.ip_rules
      virtual_network_subnet_ids = network_rules.value.virtual_network_subnet_ids
    }
  }
}

resource "azurerm_storage_container" "containers" {
  for_each = var.containers

  name                  = each.key
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = each.value.access_type
}

# Optional: management lock (enable via create_delete_lock = true in tfvars)
resource "azurerm_management_lock" "main" {
  for_each = var.create_delete_lock ? toset(["lock"]) : toset([])

  name       = "${var.name}-lock"
  scope      = azurerm_storage_account.main.id
  lock_level = "CanNotDelete"
}
