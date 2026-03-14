output "id" {
  description = "ID of the storage account"
  value       = azurerm_storage_account.main.id
}

output "storage_account_id" {
  description = "ID of the storage account"
  value       = azurerm_storage_account.main.id
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.main.name
}

output "primary_connection_string" {
  description = "Primary connection string (sensitive)"
  value       = azurerm_storage_account.main.primary_connection_string
  sensitive   = true
}

output "primary_access_key" {
  description = "Primary access key (sensitive)"
  value       = azurerm_storage_account.main.primary_access_key
  sensitive   = true
}

