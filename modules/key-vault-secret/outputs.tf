output "id" {
  description = "Secret resource ID"
  value       = azurerm_key_vault_secret.main.id
}

output "secret_id" {
  description = "Secret URI (versioned)"
  value       = azurerm_key_vault_secret.main.id
}

output "version" {
  description = "Current version of the secret"
  value       = azurerm_key_vault_secret.main.version
}
