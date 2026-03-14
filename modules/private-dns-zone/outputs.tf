output "id" {
  description = "Private DNS zone ID (use for private endpoint private_dns_zone_group)"
  value       = azurerm_private_dns_zone.main.id
}

output "name" {
  description = "Zone name"
  value       = azurerm_private_dns_zone.main.name
}
