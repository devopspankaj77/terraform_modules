##################################
# Common Tags
##################################

locals {
  # Company-mandatory tags (must be present on all resources)
  common_tags = merge({
    "Created By"       = var.created_by
    "Created Date"     = (var.created_date != null && var.created_date != "") ? var.created_date : formatdate("YYYY-MM-DD", timestamp())
    "Environment"      = var.environment
    "Requester"        = var.requester
    "Ticket Reference" = var.ticket_reference
    "Project Name"     = var.project_name
  }, var.additional_tags)

  # When jump is Windows: override RDP source for subnet-jump if jump_rdp_source_cidr is set.
  # When jump is Linux: override SSH source for subnet-jump if jump_ssh_source_cidr is set.
  jump_is_windows = try(var.vms["vm-jump"].os_type, "linux") == "windows"
  nsg_rules_effective = local.jump_is_windows ? (
    var.jump_rdp_source_cidr != null ? merge(var.nsg_rules, {
      "subnet-jump" = merge(
        try(var.nsg_rules["subnet-jump"], {}),
        {
          "allow_rdp" = merge(
            try(var.nsg_rules["subnet-jump"]["allow_rdp"], {}),
            { source_address_prefix = var.jump_rdp_source_cidr }
          )
        }
      )
    }) : var.nsg_rules
  ) : (
    var.jump_ssh_source_cidr != null ? merge(var.nsg_rules, {
      "subnet-jump" = merge(
        try(var.nsg_rules["subnet-jump"], {}),
        {
          "allow_ssh" = merge(
            try(var.nsg_rules["subnet-jump"]["allow_ssh"], {}),
            { source_address_prefix = var.jump_ssh_source_cidr }
          )
        }
      )
    }) : var.nsg_rules
  )

  # Which private endpoint types are in use (for on-demand private DNS zones)
  pe_target_types = { for k, v in var.private_endpoints : v.target_type => 1 }
  has_sql_pe         = try(local.pe_target_types["sql"], 0) != 0
  has_mysql_pe       = try(local.pe_target_types["mysql"], 0) != 0
  has_redis_pe       = try(local.pe_target_types["redis"], 0) != 0
  has_acr_pe         = try(local.pe_target_types["acr"], 0) != 0
  has_app_service_pe = try(local.pe_target_types["app_service"], 0) != 0
}

##################################
# Resource Group
##################################

module "rg" {
  source      = "../../modules/resource-group"
  name        = var.rg.name
  location    = var.rg.location
  tags        = local.common_tags
  create_lock = try(var.rg.create_lock, false)
  lock_level  = try(var.rg.lock_level, "CanNotDelete")
}

##################################
# VNets (Scalable)
##################################

module "vnets" {
  for_each = var.vnets

  source                         = "../../modules/vnet"
  name                           = each.value.name
  location                       = var.rg.location
  resource_group_name            = module.rg.name
  address_space                  = each.value.address_space
  subnets                        = each.value.subnets
  create_nsg                     = each.value.create_nsg
  nsg_per_subnet                 = each.value.nsg_per_subnet
  nsg_rules                      = local.nsg_rules_effective
  subnets_allow_private_endpoint  = toset(try(each.value.subnets_allow_private_endpoint, []))
  tags                           = local.common_tags
}

##################################
# Virtual Machines (Scalable)
##################################

module "vms" {
  for_each = var.vms

  source = "../../modules/vm"

  name                = each.value.name
  location            = var.rg.location
  resource_group_name = module.rg.name
  subnet_id           = module.vnets[each.value.vnet_key].subnet_ids[each.value.subnet_key]

  admin_username = each.value.admin_username

  # Windows: admin_password required. Prefer per-VM, then TF_VAR_jump_admin_password; fallback placeholder so plan/apply runs (change in tfvars or set env var for real password).
  admin_password = try(each.value.admin_password, each.key == "vm-jump" ? (var.jump_admin_password != null ? var.jump_admin_password : "ChangeMe123!Abc") : null)

  ssh_public_key = (
    each.value.ssh_public_key != null ?
    each.value.ssh_public_key :
    var.ssh_public_key
  )

  size              = each.value.size
  os_type           = each.value.os_type
  create_public_ip  = try(each.value.public_ip, false)
  boot_diagnostics_enabled       = try(each.value.boot_diagnostics_enabled, false)
  boot_diagnostics_storage_uri   = try(each.value.boot_diagnostics_storage_uri, null)
  availability_zone              = try(each.value.availability_zone, null)
  os_disk_type                   = try(each.value.os_disk_type, "Standard_LRS")
  os_disk_size_gb                = try(each.value.os_disk_size_gb, 128)
  os_disk_name                   = try(each.value.os_disk_name, null)
  delete_os_disk_on_termination   = try(each.value.delete_os_disk_on_termination, true)
  computer_name                  = try(each.value.computer_name, null)
  custom_data                    = try(each.value.custom_data, null)
  encryption_at_host_enabled     = try(each.value.encryption_at_host_enabled, false)

  tags = local.common_tags
}

##################################
# Storage Accounts (Scalable)
##################################

module "storage_accounts" {
  for_each = var.storage_accounts

  source = "../../modules/storage-account"

  name                              = each.value.name
  resource_group_name               = module.rg.name
  location                          = var.rg.location
  account_tier                      = each.value.account_tier
  replication_type                  = each.value.replication_type
  account_kind                      = each.value.account_kind
  min_tls_version                   = each.value.min_tls_version
  enable_blob_versioning            = each.value.enable_blob_versioning
  containers                        = each.value.containers
  blob_soft_delete_retention_days   = try(each.value.blob_soft_delete_retention_days, null)
  container_soft_delete_retention_days = try(each.value.container_soft_delete_retention_days, null)
  shared_key_access_disabled        = try(each.value.shared_key_access_disabled, false)
  network_rules                     = try(each.value.network_rules, null)
  create_delete_lock                = try(each.value.create_delete_lock, false)

  tags = local.common_tags
}

##################################
# Key Vaults (Scalable)
##################################

data "azurerm_client_config" "current" {}



module "keyvaults" {
  for_each = var.keyvaults

  source              = "../../modules/keyvault"
  name                = each.value.name
  resource_group_name = module.rg.name
  location            = var.rg.location
  sku_name            = each.value.sku_name

  rbac_authorization_enabled = try(each.value.rbac_authorization_enabled, true)
  purge_protection_enabled   = try(each.value.purge_protection_enabled, true)
  soft_delete_retention_days = try(each.value.soft_delete_retention_days, 30)
  network_acls               = try(each.value.network_acls, null)
  create_delete_lock         = try(each.value.create_delete_lock, false)

  tags = local.common_tags
}

# ----------------------------------------------- 
# role assignment for current user to manage secrets in Key Vault (only when keyvaults are defined)
# ------------------------------------------------------

resource "azurerm_role_assignment" "kv_secrets_officer" {
  for_each = module.keyvaults

  scope                = each.value.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

##################################
# Private DNS zones for Private Endpoints (recommended for private resolution)
##################################

resource "azurerm_private_dns_zone" "blob" {
  for_each             = length(var.private_endpoints) > 0 ? toset(["blob"]) : toset([])
  name                 = "privatelink.blob.core.windows.net"
  resource_group_name  = module.rg.name
  tags                 = local.common_tags
}

resource "azurerm_private_dns_zone" "vault" {
  for_each             = length(var.private_endpoints) > 0 ? toset(["vault"]) : toset([])
  name                 = "privatelink.vaultcore.azure.net"
  resource_group_name  = module.rg.name
  tags                 = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  for_each             = length(var.private_endpoints) > 0 ? toset(["blob"]) : toset([])
  name                 = "blob-${module.vnets[keys(var.vnets)[0]].vnet_name}-link"
  resource_group_name  = module.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.blob["blob"].name
  virtual_network_id   = module.vnets[keys(var.vnets)[0]].vnet_id
  tags                 = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "vault" {
  for_each             = length(var.private_endpoints) > 0 ? toset(["vault"]) : toset([])
  name                 = "vault-${module.vnets[keys(var.vnets)[0]].vnet_name}-link"
  resource_group_name  = module.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.vault["vault"].name
  virtual_network_id   = module.vnets[keys(var.vnets)[0]].vnet_id
  tags                 = local.common_tags
}

# Optional private DNS zones for SQL, MySQL, Redis, ACR, App Service (created when a PE of that type exists)
resource "azurerm_private_dns_zone" "sql" {
  for_each            = local.has_sql_pe ? toset(["sql"]) : toset([])
  name                = "privatelink.database.windows.net"
  resource_group_name = module.rg.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone" "mysql" {
  for_each            = local.has_mysql_pe ? toset(["mysql"]) : toset([])
  name                = "privatelink.mysql.database.azure.com"
  resource_group_name = module.rg.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone" "redis" {
  for_each            = local.has_redis_pe ? toset(["redis"]) : toset([])
  name                = "privatelink.redis.cache.windows.net"
  resource_group_name = module.rg.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone" "acr" {
  for_each            = local.has_acr_pe ? toset(["acr"]) : toset([])
  name                = "privatelink.azurecr.io"
  resource_group_name = module.rg.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone" "webapp" {
  for_each            = local.has_app_service_pe ? toset(["webapp"]) : toset([])
  name                = "privatelink.azurewebsites.net"
  resource_group_name = module.rg.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql" {
  for_each             = local.has_sql_pe ? toset(["sql"]) : toset([])
  name                 = "sql-${module.vnets[keys(var.vnets)[0]].vnet_name}-link"
  resource_group_name  = module.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.sql["sql"].name
  virtual_network_id   = module.vnets[keys(var.vnets)[0]].vnet_id
  tags                 = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "mysql" {
  for_each             = local.has_mysql_pe ? toset(["mysql"]) : toset([])
  name                 = "mysql-${module.vnets[keys(var.vnets)[0]].vnet_name}-link"
  resource_group_name  = module.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.mysql["mysql"].name
  virtual_network_id   = module.vnets[keys(var.vnets)[0]].vnet_id
  tags                 = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "redis" {
  for_each             = local.has_redis_pe ? toset(["redis"]) : toset([])
  name                 = "redis-${module.vnets[keys(var.vnets)[0]].vnet_name}-link"
  resource_group_name  = module.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.redis["redis"].name
  virtual_network_id   = module.vnets[keys(var.vnets)[0]].vnet_id
  tags                 = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr" {
  for_each             = local.has_acr_pe ? toset(["acr"]) : toset([])
  name                 = "acr-${module.vnets[keys(var.vnets)[0]].vnet_name}-link"
  resource_group_name  = module.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.acr["acr"].name
  virtual_network_id   = module.vnets[keys(var.vnets)[0]].vnet_id
  tags                 = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "webapp" {
  for_each             = local.has_app_service_pe ? toset(["webapp"]) : toset([])
  name                 = "webapp-${module.vnets[keys(var.vnets)[0]].vnet_name}-link"
  resource_group_name  = module.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.webapp["webapp"].name
  virtual_network_id   = module.vnets[keys(var.vnets)[0]].vnet_id
  tags                 = local.common_tags
}

##################################
# Private Endpoints (Scalable – all PaaS types)
##################################

module "private_endpoints" {
  for_each = var.private_endpoints

  source              = "../../modules/private-endpoint"
  name                = each.value.name
  location            = var.rg.location
  resource_group_name = module.rg.name

  subnet_id = module.vnets[each.value.vnet_key].subnet_ids[each.value.subnet_key]

  # Resolve target resource ID by type (target_key must exist in the corresponding module)
  target_resource_id = (
    each.value.target_type == "storage"       ? module.storage_accounts[each.value.target_key].id :
    each.value.target_type == "keyvault"     ? module.keyvaults[each.value.target_key].id :
    each.value.target_type == "sql"          ? module.sql_servers[each.value.target_key].sql_server_id :
    each.value.target_type == "mysql"        ? module.mysql_servers[each.value.target_key].id :
    each.value.target_type == "redis"        ? module.redis_caches[each.value.target_key].id :
    each.value.target_type == "acr"          ? module.registries[each.value.target_key].id :
    each.value.target_type == "app_service"  ? module.app_services[each.value.target_key].web_app_id :
    null
  )

  subresource_name = each.value.subresource_name

  # Private DNS zone per type (FQDN resolves to private IP)
  private_dns_zone_id = (
    each.value.target_type == "storage" && length(azurerm_private_dns_zone.blob) > 0       ? azurerm_private_dns_zone.blob["blob"].id :
    each.value.target_type == "keyvault" && length(azurerm_private_dns_zone.vault) > 0     ? azurerm_private_dns_zone.vault["vault"].id :
    each.value.target_type == "sql" && length(azurerm_private_dns_zone.sql) > 0             ? azurerm_private_dns_zone.sql["sql"].id :
    each.value.target_type == "mysql" && length(azurerm_private_dns_zone.mysql) > 0         ? azurerm_private_dns_zone.mysql["mysql"].id :
    each.value.target_type == "redis" && length(azurerm_private_dns_zone.redis) > 0        ? azurerm_private_dns_zone.redis["redis"].id :
    each.value.target_type == "acr" && length(azurerm_private_dns_zone.acr) > 0           ? azurerm_private_dns_zone.acr["acr"].id :
    each.value.target_type == "app_service" && length(azurerm_private_dns_zone.webapp) > 0  ? azurerm_private_dns_zone.webapp["webapp"].id :
    null
  )

  tags = local.common_tags
}

##################################
# Azure Bastion (Scalable)
##################################

module "bastions" {
  for_each = var.bastions

  source = "../../modules/bastion"

  name               = each.value.name
  public_ip_name     = each.value.public_ip_name
  location           = var.rg.location
  resource_group_name = module.rg.name

  subnet_id = module.vnets[each.value.vnet_key].subnet_ids[each.value.subnet_key]

  sku                = try(each.value.sku, "Standard")
  scale_units         = try(each.value.scale_units, 2)
  copy_paste_enabled  = try(each.value.copy_paste_enabled, true)
  file_copy_enabled   = try(each.value.file_copy_enabled, false)
  tunneling_enabled   = try(each.value.tunneling_enabled, false)

  tags = local.common_tags
}

##################################
# SQL Servers (Scalable)
##################################

module "sql_servers" {
  for_each = var.sql_servers

  source = "../../modules/sql"

  server_name          = each.value.server_name
  location             = var.rg.location
  resource_group_name  = module.rg.name
  admin_username       = each.value.admin_username
  admin_password       = each.value.admin_password
  sql_version          = try(each.value.sql_version, "12.0")
  min_tls_version      = try(each.value.min_tls_version, "1.2")
  firewall_rules       = try(each.value.firewall_rules, {})
  databases            = try(each.value.databases, {})
  azuread_administrator = try(each.value.azuread_administrator, null)
  extended_auditing_policy = try(each.value.extended_auditing_policy, null)
  tags                 = local.common_tags
}

##################################
# Redis Caches (Scalable)
##################################

module "redis_caches" {
  for_each = var.redis_caches

  source = "../../modules/redis"

  name                = each.value.name
  location            = var.rg.location
  resource_group_name = module.rg.name
  capacity            = try(each.value.capacity, 0)
  family              = try(each.value.family, "C")
  sku_name            = try(each.value.sku_name, "Basic")
  non_ssl_port_enabled = try(each.value.non_ssl_port_enabled, false)
  minimum_tls_version = try(each.value.minimum_tls_version, "1.2")
  tags                = local.common_tags
}

##################################
# MySQL Flexible Servers (Scalable)
##################################

module "mysql_servers" {
  for_each = var.mysql_servers

  source = "../../modules/mysql"

  name                    = each.value.name
  location                = var.rg.location
  resource_group_name     = module.rg.name
  administrator_login     = each.value.administrator_login
  administrator_password  = each.value.administrator_password
  sku_name               = try(each.value.sku_name, "GP_Standard_D2ds_v4")
  mysql_version          = try(each.value.mysql_version, "8.0.21")
  storage_size_gb        = try(each.value.storage_size_gb, 20)
  backup_retention_days   = try(each.value.backup_retention_days, 7)
  databases              = try(each.value.databases, {})
  firewall_rules         = try(each.value.firewall_rules, {})
  tags                   = local.common_tags
}

##################################
# App Services (Scalable)
##################################

module "app_services" {
  for_each = var.app_services

  source = "../../modules/app-service"

  name                      = each.value.name
  plan_name                 = each.value.plan_name
  location                  = var.rg.location
  resource_group_name       = module.rg.name
  os_type                   = try(each.value.os_type, "Linux")
  sku_name                  = try(each.value.sku_name, "B1")
  app_settings              = try(each.value.app_settings, {})
  connection_strings       = try(each.value.connection_strings, {})
  health_check_path         = try(each.value.health_check_path, null)
  https_only                = try(each.value.https_only, true)
  client_certificate_enabled = try(each.value.client_certificate_enabled, false)
  always_on                 = try(each.value.always_on, null)
  identity_enabled          = try(each.value.identity_enabled, true)
  tags                      = local.common_tags
}

##################################
# Function Apps (Scalable)
##################################

module "function_apps" {
  for_each = var.function_apps

  source = "../../modules/function-app"

  name                 = each.value.name
  plan_name            = each.value.plan_name
  location             = var.rg.location
  resource_group_name  = module.rg.name
  sku_name             = try(each.value.sku_name, "Y1")
  storage_account_name = try(each.value.storage_account_name, "${replace(each.value.name, "-", "")}stg")
  existing_storage_account_name = try(each.value.storage_account_key, null) != null ? module.storage_accounts[each.value.storage_account_key].storage_account_name : null
  existing_storage_account_access_key = try(each.value.storage_account_key, null) != null ? module.storage_accounts[each.value.storage_account_key].primary_access_key : null
  app_settings         = try(each.value.app_settings, {})
  tags                 = local.common_tags
}

##################################
# Logic Apps Standard (Scalable)
##################################

module "logic_apps" {
  for_each = var.logic_apps

  source = "../../modules/logic-app"

  name                   = each.value.name
  location                = var.rg.location
  resource_group_name     = module.rg.name
  app_service_plan_id     = module.app_services[each.value.app_service_plan_key].app_service_plan_id
  storage_account_name   = module.storage_accounts[each.value.storage_account_key].storage_account_name
  storage_account_access_key = module.storage_accounts[each.value.storage_account_key].primary_access_key
  app_settings            = try(each.value.app_settings, {})
  tags                    = local.common_tags
}

##################################
# API Management (Scalable)
##################################

module "api_managements" {
  for_each = var.api_managements

  source = "../../modules/api-management"

  name                = each.value.name
  location            = var.rg.location
  resource_group_name = module.rg.name
  publisher_name      = each.value.publisher_name
  publisher_email     = each.value.publisher_email
  sku_name            = try(each.value.sku_name, "Developer")
  subnet_id           = try(each.value.vnet_key, null) != null && try(each.value.subnet_key, null) != null ? module.vnets[each.value.vnet_key].subnet_ids[each.value.subnet_key] : null
  tags                = local.common_tags
}

##################################
# AKS Clusters (Scalable)
##################################

module "aks_clusters" {
  for_each = var.aks_clusters

  source = "../../modules/aks"

  name                        = each.value.name
  location                     = var.rg.location
  resource_group_name         = module.rg.name
  dns_prefix                   = each.value.dns_prefix
  vnet_subnet_id              = module.vnets[each.value.vnet_key].subnet_ids[each.value.subnet_key]
  kubernetes_version          = try(each.value.kubernetes_version, null)
  default_node_pool_vm_size              = try(each.value.default_node_pool_vm_size, "Standard_DS2_v2")
  default_node_pool_node_count           = try(each.value.default_node_pool_node_count, 1)
  default_node_pool_enable_auto_scaling  = try(each.value.default_node_pool_enable_auto_scaling, false)
  default_node_pool_min_count            = try(each.value.default_node_pool_min_count, 1)
  default_node_pool_max_count            = try(each.value.default_node_pool_max_count, 3)
  enable_azure_rbac                     = try(each.value.enable_azure_rbac, false)
  network_plugin                        = try(each.value.network_plugin, "kubenet")
  user_node_pools                       = try(each.value.user_node_pools, {})
  tags                                  = local.common_tags
}

##################################
# Container Registries (Scalable)
##################################

module "registries" {
  for_each = var.registries

  source = "../../modules/registry"

  name                = each.value.name
  location            = var.rg.location
  resource_group_name = module.rg.name
  sku                 = try(each.value.sku, "Basic")
  admin_enabled       = try(each.value.admin_enabled, false)
  public_network_access_enabled = try(each.value.public_network_access_enabled, true)
  tags                = local.common_tags
}

##################################
# Log Analytics Workspaces (Scalable)
##################################

module "log_analytics_workspaces" {
  for_each = var.log_analytics_workspaces

  source = "../../modules/log-analytics"

  name                = each.value.name
  location             = var.rg.location
  resource_group_name  = module.rg.name
  sku                  = try(each.value.sku, "PerGB2018")
  retention_in_days    = try(each.value.retention_in_days, 30)
  tags                 = local.common_tags
}

##################################
# Application Insights (Scalable)
##################################

module "application_insights" {
  for_each = var.application_insights

  source = "../../modules/application-insights"

  name                = each.value.name
  location             = var.rg.location
  resource_group_name  = module.rg.name
  application_type     = try(each.value.application_type, "web")
  workspace_id         = try(each.value.workspace_key, null) != null && contains(keys(module.log_analytics_workspaces), each.value.workspace_key) ? module.log_analytics_workspaces[each.value.workspace_key].id : null
  tags                 = local.common_tags
}

##################################
# User-Assigned Managed Identities (Scalable)
##################################

module "managed_identities" {
  for_each = var.managed_identities

  source = "../../modules/managed-identity"

  name                = each.value.name
  location             = var.rg.location
  resource_group_name  = module.rg.name
  tags                 = local.common_tags
}

##################################
# NAT Gateways (Scalable)
##################################

module "nat_gateways" {
  for_each = var.nat_gateways

  source = "../../modules/nat-gateway"

  name                    = each.value.name
  public_ip_name           = each.value.public_ip_name
  location                 = var.rg.location
  resource_group_name      = module.rg.name
  idle_timeout_in_minutes  = try(each.value.idle_timeout_in_minutes, 10)
  tags                     = local.common_tags
}

##################################
# Recovery Services Vaults (Scalable)
##################################

module "recovery_services_vaults" {
  for_each = var.recovery_services_vaults

  source = "../../modules/recovery-services"

  name                = each.value.name
  location            = var.rg.location
  resource_group_name = module.rg.name
  sku                 = try(each.value.sku, "Standard")
  soft_delete_enabled = try(each.value.soft_delete_enabled, true)
  create_delete_lock  = try(each.value.create_delete_lock, false)
  tags                = local.common_tags
}

##################################
# Private DNS Zones (Scalable – link to VNets)
##################################

module "private_dns_zones" {
  for_each = var.private_dns_zones

  source = "../../modules/private-dns-zone"

  zone_name             = each.value.zone_name
  resource_group_name   = module.rg.name
  virtual_network_ids   = [for k in each.value.vnet_keys : module.vnets[k].vnet_id]
  registration_enabled  = try(each.value.registration_enabled, false)
  tags                  = local.common_tags
}

##################################
# Key Vault Secrets (Scalable – use existing Key Vault)
##################################

module "key_vault_secrets" {
  for_each = var.key_vault_secrets

  source = "../../modules/key-vault-secret"

  secret_name   = each.value.secret_name
  secret_value  = each.value.secret_value
  key_vault_id  = module.keyvaults[each.value.key_vault_key].id
  content_type  = try(each.value.content_type, null)
  tags          = local.common_tags

  depends_on = [azurerm_role_assignment.terraform_kv_secrets_officer]
}

##################################
# VM RBAC – Azure AD login (dev/prod)
##################################

# Assign VM Admin Login to current client for vm-app (only when vms.vm-app is defined)
resource "azurerm_role_assignment" "vm_admin_login" {
  for_each             = contains(keys(var.vms), "vm-app") ? toset(["vm-app"]) : toset([])
  scope                = module.vms["vm-app"].vm_id
  role_definition_name = "Virtual Machine Administrator Login"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Assign VM Admin Login to current client for vm-jump (enables RDP/SSH via Azure AD to jump box)
resource "azurerm_role_assignment" "vm_jump_admin_login" {
  for_each             = contains(keys(var.vms), "vm-jump") ? toset(["vm-jump"]) : toset([])
  scope                = module.vms["vm-jump"].vm_id
  role_definition_name = "Virtual Machine Administrator Login"
  principal_id         = data.azurerm_client_config.current.object_id
}

# VM RBAC roles reference:
# | Role                                | Access     |
# | ----------------------------------- | ---------- |
# | Virtual Machine User Login          | SSH user   |
# | Virtual Machine Administrator Login | sudo/admin |
