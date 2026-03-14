output "id" {
  value = azurerm_linux_function_app.main.id
}

output "default_hostname" {
  value = azurerm_linux_function_app.main.default_hostname
}

output "outbound_ip_addresses" {
  value = azurerm_linux_function_app.main.outbound_ip_addresses
}
