output "id" {
  description = "Application Insights resource ID"
  value       = azurerm_application_insights.main.id
}

output "instrumentation_key" {
  description = "Instrumentation key for apps"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

output "connection_string" {
  description = "Connection string for apps"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

output "app_id" {
  description = "App ID (GUID)"
  value       = azurerm_application_insights.main.app_id
}
