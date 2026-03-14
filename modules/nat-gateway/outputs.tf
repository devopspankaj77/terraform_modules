output "id" {
  description = "NAT gateway resource ID (assign to subnet nat_gateway_id)"
  value       = azurerm_nat_gateway.main.id
}

output "public_ip_address" {
  description = "Outbound public IP address"
  value       = azurerm_public_ip.nat.ip_address
}

output "public_ip_id" {
  description = "Public IP resource ID"
  value       = azurerm_public_ip.nat.id
}
