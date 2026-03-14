# Dev environment outputs

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

# Jump VM access (Windows: RDP; Linux: SSH)
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

# -----------------------------------------------------------------------------
# SQL Servers
# -----------------------------------------------------------------------------
output "sql_server_fqdns" {
  description = "Map of SQL server logical names to FQDNs"
  value       = { for k, v in module.sql_servers : k => v.sql_server_fqdn }
}

output "sql_server_ids" {
  description = "Map of SQL server logical names to resource IDs"
  value       = { for k, v in module.sql_servers : k => v.sql_server_id }
}

# -----------------------------------------------------------------------------
# Redis Caches
# -----------------------------------------------------------------------------
output "redis_hostnames" {
  description = "Map of Redis cache logical names to hostnames"
  value       = { for k, v in module.redis_caches : k => v.hostname }
}

output "redis_ids" {
  description = "Map of Redis cache logical names to resource IDs"
  value       = { for k, v in module.redis_caches : k => v.id }
}

# -----------------------------------------------------------------------------
# MySQL Servers
# -----------------------------------------------------------------------------
output "mysql_fqdns" {
  description = "Map of MySQL server logical names to FQDNs"
  value       = { for k, v in module.mysql_servers : k => v.fqdn }
}

output "mysql_ids" {
  description = "Map of MySQL server logical names to resource IDs"
  value       = { for k, v in module.mysql_servers : k => v.id }
}

# -----------------------------------------------------------------------------
# App Services
# -----------------------------------------------------------------------------
output "app_service_hostnames" {
  description = "Map of App Service logical names to default hostnames"
  value       = { for k, v in module.app_services : k => v.default_hostname }
}

output "app_service_plan_ids" {
  description = "Map of App Service logical names to App Service Plan IDs"
  value       = { for k, v in module.app_services : k => v.app_service_plan_id }
}

# -----------------------------------------------------------------------------
# Function Apps
# -----------------------------------------------------------------------------
output "function_app_hostnames" {
  description = "Map of Function App logical names to default hostnames"
  value       = { for k, v in module.function_apps : k => v.default_hostname }
}

# -----------------------------------------------------------------------------
# Logic Apps
# -----------------------------------------------------------------------------
output "logic_app_hostnames" {
  description = "Map of Logic App logical names to default hostnames"
  value       = { for k, v in module.logic_apps : k => v.default_hostname }
}

# -----------------------------------------------------------------------------
# API Management
# -----------------------------------------------------------------------------
output "api_management_gateway_urls" {
  description = "Map of API Management logical names to gateway URLs"
  value       = { for k, v in module.api_managements : k => v.gateway_url }
}

# -----------------------------------------------------------------------------
# AKS Clusters
# -----------------------------------------------------------------------------
output "aks_fqdns" {
  description = "Map of AKS cluster logical names to API server FQDNs"
  value       = { for k, v in module.aks_clusters : k => v.aks_fqdn }
}

output "aks_node_resource_groups" {
  description = "Map of AKS cluster logical names to node resource group names"
  value       = { for k, v in module.aks_clusters : k => v.node_resource_group }
}

# -----------------------------------------------------------------------------
# Container Registries
# -----------------------------------------------------------------------------
output "registry_login_servers" {
  description = "Map of ACR logical names to login server URLs"
  value       = { for k, v in module.registries : k => v.login_server }
}

# -----------------------------------------------------------------------------
# Azure Bastion
# -----------------------------------------------------------------------------
output "bastion_ids" {
  description = "Map of Bastion logical names to Bastion Host IDs"
  value       = { for k, v in module.bastions : k => v.bastion_id }
}

output "bastion_public_ips" {
  description = "Map of Bastion logical names to Public IP addresses"
  value       = { for k, v in module.bastions : k => v.public_ip_address }
}

# -----------------------------------------------------------------------------
# Log Analytics Workspaces
# -----------------------------------------------------------------------------
output "log_analytics_workspace_ids" {
  description = "Map of Log Analytics workspace logical names to resource IDs"
  value       = { for k, v in module.log_analytics_workspaces : k => v.id }
}

output "log_analytics_workspace_ids_customer" {
  description = "Map of workspace (customer) IDs for agents and linking"
  value       = { for k, v in module.log_analytics_workspaces : k => v.workspace_id }
}

# -----------------------------------------------------------------------------
# Application Insights
# -----------------------------------------------------------------------------
output "application_insights_app_ids" {
  description = "Map of Application Insights logical names to app IDs"
  value       = { for k, v in module.application_insights : k => v.app_id }
}

# -----------------------------------------------------------------------------
# Managed Identities
# -----------------------------------------------------------------------------
output "managed_identity_principal_ids" {
  description = "Map of managed identity logical names to principal IDs (for RBAC)"
  value       = { for k, v in module.managed_identities : k => v.principal_id }
}

# -----------------------------------------------------------------------------
# NAT Gateways
# -----------------------------------------------------------------------------
output "nat_gateway_ids" {
  description = "Map of NAT gateway logical names to resource IDs (assign to subnet nat_gateway_id)"
  value       = { for k, v in module.nat_gateways : k => v.id }
}

output "nat_gateway_public_ips" {
  description = "Map of NAT gateway logical names to outbound public IP addresses"
  value       = { for k, v in module.nat_gateways : k => v.public_ip_address }
}

# -----------------------------------------------------------------------------
# Recovery Services Vaults
# -----------------------------------------------------------------------------
output "recovery_services_vault_ids" {
  description = "Map of Recovery Services vault logical names to resource IDs"
  value       = { for k, v in module.recovery_services_vaults : k => v.id }
}

# -----------------------------------------------------------------------------
# Private DNS Zones
# -----------------------------------------------------------------------------
output "private_dns_zone_ids" {
  description = "Map of Private DNS zone logical names to zone IDs (for private endpoint integration)"
  value       = { for k, v in module.private_dns_zones : k => v.id }
}
