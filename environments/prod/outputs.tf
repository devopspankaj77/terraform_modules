# =============================================================================
# Production Environment Outputs — Same structure as dev
# =============================================================================
# Map-based outputs; no sensitive values. Use Key Vault or TF_VAR for secrets.
# =============================================================================

output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.rg.name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = module.rg.id
}

output "vnet_ids" {
  description = "Map of VNet logical names to IDs"
  value       = { for k, v in module.vnets : k => v.vnet_id }
}

output "subnet_ids" {
  description = "Map of VNet name -> subnet name -> subnet ID"
  value       = { for k, v in module.vnets : k => v.subnet_ids }
}

output "vm_private_ips" {
  description = "Map of VM logical names to private IP addresses"
  value       = { for k, v in module.vms : k => v.private_ip_address }
}

output "jump_vm_public_ip" {
  description = "Public IP of the jump VM (use for RDP when Windows, or SSH when Linux)"
  value       = contains(keys(var.vms), "vm-jump") ? module.vms["vm-jump"].public_ip_address : null
}

output "jump_vm_connection_hint" {
  description = "How to connect to the jump VM after deploy"
  value       = contains(keys(var.vms), "vm-jump") ? (
    try(var.vms["vm-jump"].os_type, "linux") == "windows"
    ? "RDP: mstsc and connect to the jump_vm_public_ip; sign in with Azure AD or local admin (see README)"
    : "SSH: ssh <admin_username>@<jump_vm_public_ip>"
  ) : null
}

output "storage_account_names" {
  description = "Map of storage account logical names to resource names"
  value       = { for k, v in module.storage_accounts : k => v.storage_account_name }
}

output "keyvault_names" {
  description = "Map of Key Vault logical names to resource names"
  value       = { for k, v in module.keyvaults : k => v.key_vault_name }
}

output "keyvault_uris" {
  description = "Map of Key Vault logical names to URIs"
  value       = { for k, v in module.keyvaults : k => v.key_vault_uri }
}

output "sql_server_fqdns" {
  description = "Map of SQL server logical names to FQDNs"
  value       = { for k, v in module.sql_servers : k => v.sql_server_fqdn }
}

output "redis_hostnames" {
  description = "Map of Redis cache logical names to hostnames"
  value       = { for k, v in module.redis_caches : k => v.hostname }
}

output "mysql_fqdns" {
  description = "Map of MySQL server logical names to FQDNs"
  value       = { for k, v in module.mysql_servers : k => v.fqdn }
}

output "app_service_hostnames" {
  description = "Map of App Service logical names to default hostnames"
  value       = { for k, v in module.app_services : k => v.default_hostname }
}

output "function_app_hostnames" {
  description = "Map of Function App logical names to default hostnames"
  value       = { for k, v in module.function_apps : k => v.default_hostname }
}

output "api_management_gateway_urls" {
  description = "Map of API Management logical names to gateway URLs"
  value       = { for k, v in module.api_managements : k => v.gateway_url }
}

output "aks_fqdns" {
  description = "Map of AKS cluster logical names to API server FQDNs"
  value       = { for k, v in module.aks_clusters : k => v.aks_fqdn }
}

output "registry_login_servers" {
  description = "Map of ACR logical names to login server URLs"
  value       = { for k, v in module.registries : k => v.login_server }
}

output "bastion_ids" {
  description = "Map of Bastion logical names to Bastion Host IDs"
  value       = { for k, v in module.bastions : k => v.bastion_id }
}
