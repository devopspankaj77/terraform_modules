output "id" {
  description = "User-assigned identity resource ID"
  value       = azurerm_user_assigned_identity.main.id
}

output "principal_id" {
  description = "Principal ID for RBAC assignments"
  value       = azurerm_user_assigned_identity.main.principal_id
}

output "client_id" {
  description = "Client ID for app configuration"
  value       = azurerm_user_assigned_identity.main.client_id
}

output "name" {
  description = "Identity name"
  value       = azurerm_user_assigned_identity.main.name
}
