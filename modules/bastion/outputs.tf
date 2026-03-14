output "bastion_id" {
  description = "Bastion Host resource ID"
  value       = azurerm_bastion_host.main.id
}

output "bastion_name" {
  description = "Bastion Host name"
  value       = azurerm_bastion_host.main.name
}

output "public_ip_id" {
  description = "Public IP ID for Bastion"
  value       = azurerm_public_ip.bastion.id
}

output "public_ip_address" {
  description = "Public IP address for Bastion"
  value       = azurerm_public_ip.bastion.ip_address
}

