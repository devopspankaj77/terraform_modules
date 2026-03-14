output "id" {
  value = azurerm_api_management.main.id
}

output "gateway_url" {
  value = azurerm_api_management.main.gateway_url
}

output "gateway_regional_url" {
  value = azurerm_api_management.main.gateway_regional_url
}

output "public_ip_addresses" {
  value = azurerm_api_management.main.public_ip_addresses
}
