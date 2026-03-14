# =============================================================================
# Dev Environment – Alternate (East US 2)
# Use this file for a second dev deployment in a different region.
# Example: terraform plan -var-file=dev-eastus2.tfvars
#
# Differences from dev.tfvars:
#   - Location: eastus2 (vs eastus)
#   - Instance/suffix: 003, EUS2 (vs 002) for globally unique names
#   - RG and all resource names updated accordingly
# Only RG is uncommented below; uncomment other blocks as needed.
# =============================================================================

# -----------------------------------------------------------------------------
# Company-mandatory tags
# -----------------------------------------------------------------------------
created_by       = "Pankaj"
created_date     = null   # Auto-fills with apply date (YYYY-MM-DD). Set to "YYYY-MM-DD" to override.
environment      = "dev"
requester        = "Application Team"
ticket_reference = "INC-12346"
project_name     = "Banking-App"

# -----------------------------------------------------------------------------
# Resource Group – East US 2, distinct name
# -----------------------------------------------------------------------------
rg = {
  name     = "rg-icr-project-terraform-dev-eastus2"
  location = "eastus2"
}

# -----------------------------------------------------------------------------
# Virtual Network – uncomment when needed (names use 003 / EUS2)
# -----------------------------------------------------------------------------
# vnets = {
#   main = {
#     name            = "icr-003-Azure-INT-VNet-Bank-Dev-EUS2"
#     address_space   = ["10.11.0.0/16"]
#     create_nsg      = true
#     nsg_per_subnet  = true
#
#     subnets = {
#       subnet-app  = { address_prefixes = ["10.11.1.0/24"] }
#       subnet-data = { address_prefixes = ["10.11.2.0/24"] }
#       subnet-jump = { address_prefixes = ["10.11.3.0/24"] }
#       subnet-aks  = { address_prefixes = ["10.11.4.0/24"] }
#       AzureBastionSubnet = { address_prefixes = ["10.11.5.0/26"] }
#     }
#   }
# }

# -----------------------------------------------------------------------------
# Virtual Machines – uncomment when needed
# -----------------------------------------------------------------------------
# vms = {
#   vm-app = {
#     name           = "icr-003-Azure-LIN-INT-Bank-App-EUS2"
#     vnet_key       = "main"
#     subnet_key     = "subnet-app"
#     admin_username = "azureuser"
#     ssh_public_key = "ssh-rsa AAAA..."  # set via TF_VAR or replace
#     size           = "Standard_B2s"
#     os_type        = "linux"
#     public_ip      = false
#   }
#   # Jump VM: Windows; set TF_VAR_jump_admin_password. RDP (port 3389) in nsg_rules.subnet-jump.
#   vm-jump = {
#     name           = "icr-003-Azure-WIN-INT-Bank-Jump-EUS2"
#     vnet_key       = "main"
#     subnet_key     = "subnet-jump"
#     admin_username = "azureadmin"
#     size           = "Standard_B2s"
#     os_type        = "windows"
#     public_ip      = true
#   }
# }

# -----------------------------------------------------------------------------
# NSG Rules – uncomment when vnets is in use (adjust prefixes for 10.11.x)
# -----------------------------------------------------------------------------
# nsg_rules = {
#   subnet-app = {
#     allow_https = {
#       priority = 110
#       direction = "Inbound"
#       access    = "Allow"
#       protocol  = "Tcp"
#       destination_port_range     = "443"
#       source_address_prefix      = "10.11.3.0/24"
#       destination_address_prefix = "*"
#     }
#   }
#   subnet-data = {
#     allow_sql = {
#       priority = 100
#       direction = "Inbound"
#       access    = "Allow"
#       protocol  = "Tcp"
#       destination_port_range     = "1433"
#       source_address_prefix      = "10.11.1.0/24"
#       destination_address_prefix = "*"
#     }
#   }
#   subnet-jump = {
#     allow_rdp = {
#       priority = 100
#       direction = "Inbound"
#       access    = "Allow"
#       protocol  = "Tcp"
#       destination_port_range     = "3389"
#       source_address_prefix      = "*"
#       destination_address_prefix = "*"
#     }
#   }
# }

# -----------------------------------------------------------------------------
# Storage Account – globally unique; no hyphens (max 24 chars)
# -----------------------------------------------------------------------------
# storage_accounts = {
#   main = {
#     name                   = "icr003intstgbanke2"
#     account_tier           = "Standard"
#     replication_type       = "ZRS"
#     account_kind           = "StorageV2"
#     min_tls_version        = "TLS1_2"
#     enable_blob_versioning = true
#     containers = { data = { access_type = "private" } }
#   }
# }

# -----------------------------------------------------------------------------
# Key Vault – globally unique name
# -----------------------------------------------------------------------------
# keyvaults = {
#   main = {
#     name                       = "icr003azureintkvbanke2"
#     sku_name                   = "standard"
#     enable_rbac_authorization  = true
#     purge_protection_enabled   = true
#     soft_delete_retention_days = 30
#   }
# }

# -----------------------------------------------------------------------------
# Private Endpoints – uncomment when storage/keyvaults and vnets are in use
# -----------------------------------------------------------------------------
# private_endpoints = {
#   storage_pe = {
#     name             = "icr-003-Azure-INT-PE-Stg-Bank-EUS2"
#     target_type      = "storage"
#     target_key       = "main"
#     vnet_key         = "main"
#     subnet_key       = "subnet-data"
#     subresource_name = "blob"
#   }
#   kv_pe = {
#     name             = "icr-003-Azure-INT-PE-KV-Bank-EUS2"
#     target_type      = "keyvault"
#     target_key       = "main"
#     vnet_key         = "main"
#     subnet_key       = "subnet-data"
#     subresource_name = "vault"
#   }
# }

# -----------------------------------------------------------------------------
# Bastion – uncomment when vnets + AzureBastionSubnet are in use
# -----------------------------------------------------------------------------
# bastions = {
#   main = {
#     name           = "icr-003-Azure-INT-Bastion-Bank-EUS2"
#     public_ip_name = "icr-003-Azure-INT-PIP-Bastion-EUS2"
#     vnet_key       = "main"
#     subnet_key     = "AzureBastionSubnet"
#     sku            = "Standard"
#     scale_units    = 2
#   }
# }

# -----------------------------------------------------------------------------
# SQL Server – use TF_VAR for admin_password
# -----------------------------------------------------------------------------
# sql_servers = {
#   main = {
#     server_name    = "icr003azureintsqlbanke2"
#     admin_username = "sqladmin"
#     admin_password = "DevP@ssw0rd123!"
#     firewall_rules = { allow_azure = { start_ip_address = "0.0.0.0", end_ip_address = "0.0.0.0" } }
#     databases      = { appdb = { sku_name = "Basic", max_size_gb = 2 } }
#   }
# }

# -----------------------------------------------------------------------------
# Redis – globally unique name
# -----------------------------------------------------------------------------
# redis_caches = {
#   main = { name = "icr003azureintredisbanke2", capacity = 0, family = "C", sku_name = "Basic" }
# }

# -----------------------------------------------------------------------------
# MySQL – use TF_VAR for administrator_password
# -----------------------------------------------------------------------------
# mysql_servers = {
#   main = {
#     name                   = "icr003azureintmysqlbanke2"
#     administrator_login    = "mysqladmin"
#     administrator_password = "DevP@ssw0rd123!"
#     sku_name               = "GP_Standard_D2ds_v4"
#     storage_size_gb         = 20
#     backup_retention_days   = 7
#     databases               = { appdb = {} }
#     firewall_rules          = {}
#   }
# }

# -----------------------------------------------------------------------------
# App Service – uncomment when needed
# -----------------------------------------------------------------------------
# app_services = {
#   main = {
#     name         = "icr-003-Azure-INT-Web-App-Bank-EUS2"
#     plan_name    = "icr-003-Azure-INT-App-Srv-Plan-Bank-EUS2"
#     os_type      = "Linux"
#     sku_name     = "B1"
#     app_settings = {}
#   }
# }

# -----------------------------------------------------------------------------
# Function App – requires storage_accounts["main"]
# -----------------------------------------------------------------------------
# function_apps = {
#   main = {
#     name                = "icr-003-Azure-INT-Func-App-Bank-EUS2"
#     plan_name           = "icr-003-Azure-INT-Func-Plan-Bank-EUS2"
#     sku_name            = "Y1"
#     storage_account_key = "main"
#     app_settings        = {}
#   }
# }

# -----------------------------------------------------------------------------
# Logic App – requires app_services["main"] and storage_accounts["main"]
# -----------------------------------------------------------------------------
# logic_apps = {
#   main = {
#     name                 = "icr-003-Azure-INT-Logic-App-Bank-EUS2"
#     app_service_plan_key = "main"
#     storage_account_key  = "main"
#     app_settings         = {}
#   }
# }

# -----------------------------------------------------------------------------
# API Management – SKU e.g. Developer_1
# -----------------------------------------------------------------------------
# api_managements = {
#   main = {
#     name             = "icr003azureintapimbanke2"
#     publisher_name   = "Platform Team"
#     publisher_email  = "platform@contoso.com"
#     sku_name         = "Developer_1"
#   }
# }

# -----------------------------------------------------------------------------
# AKS – uncomment when needed (long create time)
# -----------------------------------------------------------------------------
# aks_clusters = {
#   main = {
#     name                                = "icr-003-Azure-INT-AKS-Bank-EUS2"
#     dns_prefix                          = "icr003aksbankeus2"
#     vnet_key                            = "main"
#     subnet_key                          = "subnet-aks"
#     default_node_pool_node_count         = 1
#     default_node_pool_vm_size            = "Standard_DS2_v2"
#     default_node_pool_enable_auto_scaling = true
#     default_node_pool_min_count          = 1
#     default_node_pool_max_count          = 5
#     enable_azure_rbac                    = false
#   }
# }

# -----------------------------------------------------------------------------
# Container Registry – alphanumeric only, 5–50 chars
# -----------------------------------------------------------------------------
# registries = {
#   main = { name = "acricr003intbanke2", sku = "Basic", admin_enabled = false }
# }

# -----------------------------------------------------------------------------
# Log Analytics – uncomment when needed
# -----------------------------------------------------------------------------
# log_analytics_workspaces = {
#   main = { name = "icr-003-Azure-INT-LogAnalytics-Bank-EUS2", sku = "PerGB2018", retention_in_days = 30 }
# }

# -----------------------------------------------------------------------------
# Application Insights – set workspace_key if log_analytics_workspaces is used
# -----------------------------------------------------------------------------
# application_insights = {
#   main = { name = "icr-003-Azure-INT-AppInsights-Bank-EUS2", application_type = "web", workspace_key = "main" }
# }

# -----------------------------------------------------------------------------
# Managed Identities
# -----------------------------------------------------------------------------
# managed_identities = {
#   app = { name = "icr-003-Azure-INT-MI-Bank-App-EUS2" }
# }

# -----------------------------------------------------------------------------
# NAT Gateway
# -----------------------------------------------------------------------------
# nat_gateways = {
#   main = {
#     name                    = "icr-003-Azure-INT-NAT-Bank-EUS2"
#     public_ip_name          = "icr-003-Azure-INT-PIP-NAT-EUS2"
#     idle_timeout_in_minutes = 10
#   }
# }

# -----------------------------------------------------------------------------
# Recovery Services Vault
# -----------------------------------------------------------------------------
# recovery_services_vaults = {
#   main = { name = "icr-003-Azure-INT-RSV-Bank-EUS2", sku = "Standard", soft_delete_enabled = true }
# }

# -----------------------------------------------------------------------------
# Private DNS Zones – vnet_keys when vnets is in use
# -----------------------------------------------------------------------------
# private_dns_zones = {
#   sql    = { zone_name = "privatelink.database.windows.net",    vnet_keys = ["main"] }
#   mysql  = { zone_name = "privatelink.mysql.database.azure.com", vnet_keys = ["main"] }
#   redis  = { zone_name = "privatelink.redis.cache.windows.net", vnet_keys = ["main"] }
#   acr    = { zone_name = "privatelink.azurecr.io",               vnet_keys = ["main"] }
#   webapp = { zone_name = "privatelink.azurewebsites.net",        vnet_keys = ["main"] }
# }

# -----------------------------------------------------------------------------
# Key Vault Secrets – use TF_VAR for secret_value in prod
# -----------------------------------------------------------------------------
# key_vault_secrets = {
#   sql-connection = {
#     secret_name   = "SqlConnectionString"
#     secret_value  = "Server=...;"
#     key_vault_key = "main"
#     content_type  = "text/plain"
#   }
# }
