# Key Vault Secret Module
# Store a secret in an existing Key Vault (RBAC: grant identity Key Vault Secrets User)

resource "azurerm_key_vault_secret" "main" {
  name         = var.secret_name
  value        = var.secret_value
  key_vault_id = var.key_vault_id
  tags         = var.tags
  content_type = try(var.content_type, null)
}