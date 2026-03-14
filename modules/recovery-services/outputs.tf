output "id" {
  description = "Recovery Services vault ID"
  value       = azurerm_recovery_services_vault.main.id
}

output "name" {
  description = "Vault name"
  value       = azurerm_recovery_services_vault.main.name
}
