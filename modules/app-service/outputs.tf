output "app_service_plan_id" {
  value = azurerm_service_plan.main.id
}

output "web_app_id" {
  value = try(azurerm_linux_web_app.main["Linux"].id, azurerm_windows_web_app.main["Windows"].id)
}

output "default_hostname" {
  value = try(azurerm_linux_web_app.main["Linux"].default_hostname, azurerm_windows_web_app.main["Windows"].default_hostname)
}

output "outbound_ip_addresses" {
  value = try(azurerm_linux_web_app.main["Linux"].outbound_ip_addresses, azurerm_windows_web_app.main["Windows"].outbound_ip_addresses)
}
