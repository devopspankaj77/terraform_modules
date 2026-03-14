output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "subnet_ids" {
  description = "Map of subnet names to IDs"
  value       = { for k, s in azurerm_subnet.subnets : k => s.id }
}

output "nsg_ids" {
  description = "Map of NSG names to IDs"
  value       = { for k, n in azurerm_network_security_group.main : k => n.id }
}

output "public_ip_ids" {
  description = "Map of public IP names to IDs"
  value       = { for k, p in azurerm_public_ip.main : k => p.id }
}

output "private_endpoint_subnet_id" {
  description = "ID of the private endpoint subnet (if created)"
  value       = var.create_private_endpoint_subnet ? azurerm_subnet.private_endpoint["pe"].id : null
}
