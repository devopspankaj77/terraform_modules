output "id" {
  description = "Log Analytics workspace ID"
  value       = azurerm_log_analytics_workspace.main.id
}

output "workspace_id" {
  description = "Workspace (customer) ID for agents and linking"
  value       = azurerm_log_analytics_workspace.main.workspace_id
}

output "primary_shared_key" {
  description = "Primary shared key for agents"
  value       = azurerm_log_analytics_workspace.main.primary_shared_key
  sensitive   = true
}

output "name" {
  description = "Log Analytics workspace name"
  value       = azurerm_log_analytics_workspace.main.name
}
