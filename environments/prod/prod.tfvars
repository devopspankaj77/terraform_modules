# =============================================================================
# Production Environment - Enterprise Ready
# =============================================================================

# Only RG and VNet/subnets are active. Uncomment other blocks below to create those resources.
# Optional resource maps (vms, nsg_rules, storage_accounts, etc.) default to {} in variables.tf.
# Only set a variable here when you want to create those resources; no need to write = {}.
# Set sensitive values via TF_VAR_* (e.g. TF_VAR_jump_admin_password, TF_VAR_sql_admin_password).
#
# ENTERPRISE SECURITY BASELINE (SECURITY_BASELINES.md / RESOURCE_CONTROLS_SHEET.md):
# - Tags: mandatory (Created By, Date, Environment, Requester, Ticket, Project) + Owner/CostCenter/DataClassification.
# - VNet: NSG per subnet; no 0.0.0.0/0 for RDP/SSH; use jump_rdp_source_cidr / jump_ssh_source_cidr (VPN/bastion CIDR).
# - VM: no public IP in prod (use Bastion); admin password via TF_VAR_jump_admin_password only.
# - Storage: GZRS/ZRS, TLS 1.2+, blob versioning; containers private; use private endpoint.
# - Key Vault: RBAC only, 90d soft delete, purge protection; use private endpoint.
# - SQL/MySQL: min TLS 1.2, firewall to app subnet/PE only; password via TF_VAR only.
# - Redis: non_ssl_port_enabled = false, minimum_tls_version = "1.2"; use private endpoint.
# - AKS: enable_azure_rbac, network_plugin = "azure", min 2 nodes; set admin group when supported.
# - ACR: admin_enabled = false, public_network_access_enabled = false when using PE.
# - App Service / Function: secrets via Key Vault references; PE for prod.
# - No secrets in committed tfvars; no terraform apply -auto-approve in prod.
#
# Naming convention (Internal project – treat as INT; or CLT for client-facing):
#   VM:        jsh-002-Azure-LIN-INT-IT-Sonar
#   Web App:   jsh-055-Azure-INT-Web-App-RAT-QA
#   Client:    jsh-051-Azure-CLT-Web-App-Cook-Medical, jsh-045-Azure-WIN-CLI-Starting-Point
#   Pattern:  jsh-<nnn>-Azure-<INT|CLT>-<ResourceType>-<Workload>
#   This env: INT, instance 002, workload Bank-Prod. Storage/ACR: no hyphens (Azure limit).
# =============================================================================

# -----------------------------------------------------------------------------
# Company-mandatory tags
# -----------------------------------------------------------------------------
created_by       = "Platform"
created_date     = null   # Set to "YYYY-MM-DD" to avoid tag drift; null = use apply date
environment      = "prod"
requester        = "Application Team"
ticket_reference = "CHG-12345"
project_name     = "terraform-enterprise"

# Optional: add extra tags (e.g. Owner, CostCenter, DataClassification)
additional_tags = {
  Owner               = "platform-team"
  CostCenter          = "prod"
  DataClassification = "Confidential"
}

# -----------------------------------------------------------------------------
# Resource Group (with proper tagging via common_tags in main.tf)
# Security options (optional – set in tfvars; see REMARKS below):
#   create_lock = true   → CanNotDelete management lock (REMARK: recommended for prod; prevents accidental RG deletion)
#   lock_level  = "CanNotDelete" | "ReadOnly"
# -----------------------------------------------------------------------------
rg = {
  name     = "rg-jsh-project-terraform-prod-eastus"
  location = "eastus"
  # create_lock = true   # REMARK: enable for prod (RESOURCE_CONTROLS_SHEET)
  # lock_level  = "CanNotDelete"
}

# -----------------------------------------------------------------------------
# Virtual Network (active – includes subnets)
# -----------------------------------------------------------------------------
vnets = {
  main = {
    name           = "jsh-002-Azure-INT-VNet-Bank-Prod"
    address_space  = ["10.2.0.0/16"]
    create_nsg     = true
    nsg_per_subnet = true

    subnets = {
      subnet-app = {
        address_prefixes = ["10.2.1.0/24"]
      }

      subnet-data = {
        address_prefixes = ["10.2.2.0/24"]
      }

      subnet-jump = {
        address_prefixes = ["10.2.3.0/24"]
      }

      subnet-aks = {
        address_prefixes = ["10.2.4.0/24"]
      }

      # Subnet for private endpoints (optional; use when creating PEs)
      private-endpoints = {
        address_prefixes = ["10.2.100.0/24"]
      }

      # Required for Azure Bastion (must be named exactly AzureBastionSubnet; /26 or larger recommended)
      AzureBastionSubnet = {
        address_prefixes = ["10.2.5.0/26"]
      }
    }
    # SECURITY_BASELINES 7.2: Subnets used for private endpoints (private_endpoint_network_policies = Disabled)
    subnets_allow_private_endpoint = ["private-endpoints"]
  }
}

# # -----------------------------------------------------------------------------
# # Virtual Machines – Prod: use Bastion (no public IP on VM); set TF_VAR_jump_admin_password when using Windows jump
# # Use jump_rdp_source_cidr / jump_ssh_source_cidr to restrict RDP/SSH source (no 0.0.0.0/0)
# # -----------------------------------------------------------------------------
# vms = {
#
#   vm-app = {
#     name           = "jsh-002-Azure-LIN-INT-Bank-App"
#     vnet_key       = "main"
#     subnet_key     = "subnet-app"
#     admin_username = "azureuser"
#     ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC0..."
#     size           = "Standard_B2s"
#     os_type        = "linux"
#     public_ip      = false
#     # Optional: os_disk_type, os_disk_size_gb, os_disk_name; computer_name; custom_data; encryption_at_host_enabled
#   }
#
#   vm-jump = {
#     name           = "jsh-002-Azure-WIN-INT-Bank-Jump"
#     vnet_key       = "main"
#     subnet_key     = "subnet-jump"
#     admin_username = "azureadmin"
#     admin_password = null   # set via TF_VAR_jump_admin_password; never commit
#     size           = "Standard_B2s"
#     os_type        = "windows"
#     public_ip      = false   # use Bastion in prod
#     # Optional: os_disk_type, os_disk_size_gb, os_disk_name; computer_name; custom_data; encryption_at_host_enabled
#     # Security (optional) – uncomment to enable:
#     # boot_diagnostics_enabled    = true
#     # boot_diagnostics_storage_uri = null   # null = managed; or set storage account URI
#     # availability_zone           = "1"   # "1"|"2"|"3" for HA
#     # REMARK: boot_diagnostics for troubleshooting; availability_zone for HA
#   }
# }
#
# # -----------------------------------------------------------------------------
# # NSG Rules – baseline: no 0.0.0.0/0 for RDP/SSH; use VPN or bastion CIDR only.
# # Set jump_rdp_source_cidr / jump_ssh_source_cidr (TF_VAR or tfvars) to override subnet-jump source.
# # Jump subnet = 10.2.3.0/24; rules allow Jump to reach App (HTTPS+SSH), Data (SQL), AKS (443+22), PE (VNet).
# # -----------------------------------------------------------------------------
# nsg_rules = {
#   subnet-app = {
#     allow_https        = { priority = 110, direction = "Inbound", access = "Allow", protocol = "Tcp", destination_port_range = "443", source_address_prefix = "10.2.3.0/24", destination_address_prefix = "*" }
#     allow_ssh_from_jump = { priority = 120, direction = "Inbound", access = "Allow", protocol = "Tcp", destination_port_range = "22", source_address_prefix = "10.2.3.0/24", destination_address_prefix = "*" }
#   }
#   subnet-data = {
#     allow_sql_from_app  = { priority = 100, direction = "Inbound", access = "Allow", protocol = "Tcp", destination_port_range = "1433", source_address_prefix = "10.2.1.0/24", destination_address_prefix = "*" }
#     allow_sql_from_jump = { priority = 110, direction = "Inbound", access = "Allow", protocol = "Tcp", destination_port_range = "1433", source_address_prefix = "10.2.3.0/24", destination_address_prefix = "*" }
#   }
#   subnet-jump = {
#     allow_rdp = { priority = 100, direction = "Inbound", access = "Allow", protocol = "Tcp", destination_port_range = "3389", source_address_prefix = "YOUR_VPN_OR_BASTION_CIDR", destination_address_prefix = "*" }
#   }
#   subnet-aks = {
#     allow_https_from_jump = { priority = 100, direction = "Inbound", access = "Allow", protocol = "Tcp", destination_port_range = "443", source_address_prefix = "10.2.3.0/24", destination_address_prefix = "*" }
#     allow_ssh_from_jump   = { priority = 110, direction = "Inbound", access = "Allow", protocol = "Tcp", destination_port_range = "22", source_address_prefix = "10.2.3.0/24", destination_address_prefix = "*" }
#   }
#   private-endpoints = {
#     allow_https_from_vnet  = { priority = 100, direction = "Inbound", access = "Allow", protocol = "Tcp", destination_port_range = "443", source_address_prefix = "10.2.0.0/16", destination_address_prefix = "*" }
#     allow_sql_from_vnet   = { priority = 110, direction = "Inbound", access = "Allow", protocol = "Tcp", destination_port_range = "1433", source_address_prefix = "10.2.0.0/16", destination_address_prefix = "*" }
#     allow_redis_from_vnet = { priority = 120, direction = "Inbound", access = "Allow", protocol = "Tcp", destination_port_range = "6380", source_address_prefix = "10.2.0.0/16", destination_address_prefix = "*" }
#   }
# }
#
# # -----------------------------------------------------------------------------
# # Storage Accounts – baseline: GZRS/ZRS, TLS 1.2+, blob versioning, private containers; use PE + private DNS
# # -----------------------------------------------------------------------------
# storage_accounts = {
#   main = {
#     name                    = "jsh002stgbankprod"   # no hyphens (Azure limit); globally unique
#     account_tier            = "Standard"
#     replication_type        = "GZRS"
#     account_kind            = "StorageV2"
#     min_tls_version         = "TLS1_2"
#     enable_blob_versioning  = true
#     containers              = { data = { access_type = "private" } }
#     # Security (optional) – uncomment to enable:
#     # blob_soft_delete_retention_days    = 30
#     # container_soft_delete_retention_days = 30
#     # shared_key_access_disabled         = true   # enable via Portal/Policy if provider unsupported
#     # create_delete_lock                 = true
#     # network_rules = { default_action = "Deny", bypass = ["AzureServices"], ip_rules = [], virtual_network_subnet_ids = [] }
#     # REMARK: 30d soft delete for prod; create_delete_lock = true for prod; network_rules when not PE-only
#   }
# }
#
# # -----------------------------------------------------------------------------
# # Azure Key Vault – baseline: RBAC only, 90d soft delete, purge protection; use PE + private DNS
# # -----------------------------------------------------------------------------
# keyvaults = {
#   main = {
#     name                       = "jsh002-kv-bank-prod-eus1"
#     sku_name                   = "standard"
#     rbac_authorization_enabled = true
#     purge_protection_enabled   = true
#     soft_delete_retention_days = 90
#     # Security (optional) – uncomment to enable:
#     # network_acls = { default_action = "Deny", bypass = "AzureServices", ip_rules = [], virtual_network_subnet_ids = [] }
#     # create_delete_lock = true
#     # REMARK: network_acls when not PE-only; create_delete_lock = true for prod
#   }
# }
#
# # -----------------------------------------------------------------------------
# # Private Endpoints – baseline: use for storage, keyvault, sql, mysql, redis, acr, app_service; private DNS auto
# # -----------------------------------------------------------------------------
# private_endpoints = {
#   storage_pe = { name = "jsh-002-Azure-INT-PE-Stg-Bank", target_type = "storage", target_key = "main", vnet_key = "main", subnet_key = "private-endpoints", subresource_name = "blob" }
#   kv_pe      = { name = "jsh-002-Azure-INT-PE-KV-Bank", target_type = "keyvault", target_key = "main", vnet_key = "main", subnet_key = "private-endpoints", subresource_name = "vault" }
#   sql_pe     = { name = "jsh-002-Azure-INT-PE-SQL-Bank", target_type = "sql", target_key = "main", vnet_key = "main", subnet_key = "private-endpoints", subresource_name = "sqlServer" }
#   mysql_pe   = { name = "jsh-002-Azure-INT-PE-MySQL-Bank", target_type = "mysql", target_key = "main", vnet_key = "main", subnet_key = "private-endpoints", subresource_name = "mysqlServer" }
#   redis_pe   = { name = "jsh-002-Azure-INT-PE-Redis-Bank", target_type = "redis", target_key = "main", vnet_key = "main", subnet_key = "private-endpoints", subresource_name = "redisCache" }
#   acr_pe     = { name = "jsh-002-Azure-INT-PE-ACR-Bank", target_type = "acr", target_key = "main", vnet_key = "main", subnet_key = "private-endpoints", subresource_name = "registry" }
#   app_pe     = { name = "jsh-002-Azure-INT-PE-WebApp-Bank", target_type = "app_service", target_key = "main", vnet_key = "main", subnet_key = "private-endpoints", subresource_name = "sites" }
# }
#
# # -----------------------------------------------------------------------------
# # Azure Bastion – baseline: Standard SKU; use for jump VM access (no public IP on VM)
# # -----------------------------------------------------------------------------
# bastions = {
#   main = { name = "jsh-002-Azure-INT-Bastion-Bank-Prod", public_ip_name = "jsh-002-Azure-INT-PIP-Bastion-Bank-Prod", vnet_key = "main", subnet_key = "AzureBastionSubnet", sku = "Standard", scale_units = 2 }
# }
#
# # -----------------------------------------------------------------------------
# # SQL Servers – baseline: min_tls_version 1.2, firewall to app subnet/PE only; admin_password via TF_VAR only
# # -----------------------------------------------------------------------------
# sql_servers = {
#   main = {
#     server_name     = "jsh002-sql-bank-prod-eus1"
#     admin_username  = "sqladmin"
#     admin_password  = ""   # set TF_VAR_sql_admin_password (or Key Vault); never commit
#     min_tls_version = "1.2"
#     firewall_rules  = {}   # restrict to app subnet IP range or leave empty when using PE only
#     databases       = { main = { sku_name = "S0", max_size_gb = 250 } }   # or add short_term_retention_days = 35 per policy (7–35)
#     # Security (optional) – uncomment to enable:
#     # azuread_administrator = { login = "sql-admins", object_id = "<azure-ad-group-object-id>", tenant_id = null }
#     # extended_auditing_policy: use azurerm_mssql_server_extended_auditing_policy in env when needed
#     # REMARK: Azure AD admin for MFA/audit; short_term_retention_days per compliance; auditing via separate resource
#   }
# }
#
# # -----------------------------------------------------------------------------
# # Redis Caches – baseline: non_ssl_port_enabled = false, minimum_tls_version = "1.2"; use PE in prod
# # -----------------------------------------------------------------------------
# redis_caches = {
#   main = {
#     name                 = "jsh002-redis-bank-prod-eus1"
#     capacity             = 1
#     family               = "C"
#     sku_name             = "Standard"
#     non_ssl_port_enabled = false
#     minimum_tls_version  = "1.2"
#   }
# }
#
# # -----------------------------------------------------------------------------
# # MySQL Flexible Servers – baseline: firewall to app subnet/PE only; administrator_password via TF_VAR only; backup_retention_days ≥ 7
# # -----------------------------------------------------------------------------
# mysql_servers = {
#   main = {
#     name                   = "jsh002-mysql-bank-prod-eus1"
#     administrator_login    = "mysqladmin"
#     administrator_password = ""   # set TF_VAR_mysql_admin_password; never commit
#     sku_name               = "GP_Standard_D2ds_v4"
#     storage_size_gb        = 128
#     backup_retention_days  = 7
#     databases              = { appdb = {} }
#     firewall_rules         = {}
#   }
# }
#
# # -----------------------------------------------------------------------------
# # App Services (Enterprise – prod: P1v2+; connection strings via Key Vault ref; health check; PE)
# # Requires: names/plan_name globally unique. For Logic Apps: use this plan via app_service_plan_key = "main".
# # Prod baseline: secrets via Key Vault references in app_settings/connection_strings; always_on = true; use PE.
# # -----------------------------------------------------------------------------
# app_services = {
#   main = {
#     name      = "jsh-002-Azure-INT-Web-App-Bank-Prod"
#     plan_name = "jsh-002-Azure-INT-App-Srv-Plan-Bank-Prod"
#     os_type   = "Linux"
#     sku_name  = "P1v2"
#     app_settings = {}
#     # Optional: connection strings (use Key Vault ref in prod: @Mjshosoft.KeyVault(SecretUri=...))
#     # connection_strings = {
#     #   DefaultConnection = { type = "SQLAzure", value = "@Mjshosoft.KeyVault(SecretUri=https://jsh002-kv-bank-prod-eus1.vault.azure.net/secrets/SqlConnectionString/)" }
#     # }
#     # health_check_path = "/health"
#     https_only                 = true
#     identity_enabled           = true
#     always_on                  = true
#     # client_certificate_enabled = false
#   }
# }
# app_services = {}
#
# # -----------------------------------------------------------------------------
# # Function Apps (Enterprise – prod: EP1/P1v2 dedicated; storage via Key Vault ref; use PE)
# # Requires: storage_accounts with key referenced by storage_account_key.
# # Prod baseline: EP1/P1v2 for SLA; app_settings secrets via Key Vault reference.
# # -----------------------------------------------------------------------------
# function_apps = {
#   main = {
#     name                = "jsh-002-Azure-INT-Func-App-Bank-Prod"
#     plan_name           = "jsh-002-Azure-INT-Func-Plan-Bank-Prod"
#     sku_name            = "EP1"
#     storage_account_key = "main"
#     app_settings        = {}
#     # Optional: app_settings with Key Vault refs for prod
#   }
# }
# function_apps = {}
#
# # -----------------------------------------------------------------------------
# # Logic Apps Standard (Enterprise – prod: use same plan as app_services; storage via Key Vault ref where possible)
# # Requires: app_services (with plan) and storage_accounts; app_service_plan_key = key in app_services.
# # -----------------------------------------------------------------------------
# logic_apps = {
#   main = {
#     name                 = "jsh-002-Azure-INT-Logic-App-Bank-Prod"
#     app_service_plan_key = "main"
#     storage_account_key  = "main"
#     app_settings         = {}
#   }
# }
# logic_apps = {}
#
# # -----------------------------------------------------------------------------
# # API Management (Enterprise – prod: Standard/Premium; VNet integration; publisher required)
# # Name: globally unique (e.g. jsh002-apim-bank-prod-eus1). Prod: use vnet_key + subnet_key for internal APIM.
# # -----------------------------------------------------------------------------
# api_managements = {
#   main = {
#     name             = "jsh002-apim-bank-prod-eus1"
#     publisher_name   = "Platform Team"
#     publisher_email  = "platform@contoso.com"
#     sku_name         = "Standard_1"
#     vnet_key         = "main"
#     subnet_key       = "subnet-app"
#     # Use dedicated subnet for APIM (e.g. subnet-apim /27) when deploying; subnet-app is example
#   }
# }
# (app_services, function_apps, logic_apps, api_managements default to {}; uncomment blocks above to create)

# # -----------------------------------------------------------------------------
# # AKS Clusters – baseline: enable_azure_rbac = true, network_plugin = "azure", min 2 nodes; set admin group when supported
# # -----------------------------------------------------------------------------
# aks_clusters = {
#   main = {
#     name                         = "jsh-002-Azure-INT-AKS-Bank-Prod"
#     dns_prefix                    = "jsh002aksbankprod"
#     vnet_key                      = "main"
#     subnet_key                    = "subnet-aks"
#     default_node_pool_node_count  = 2
#     default_node_pool_vm_size     = "Standard_F4s_v2"
#     default_node_pool_enable_auto_scaling = true
#     default_node_pool_min_count   = 2
#     default_node_pool_max_count   = 10
#     enable_azure_rbac             = true
#     network_plugin                = "azure"
#   }
# }
#
# # -----------------------------------------------------------------------------
# # Container Registries – baseline: admin_enabled = false; public_network_access_enabled = false when using PE
# # -----------------------------------------------------------------------------
# registries = {
#   main = {
#     name                          = "acrjsh002intbankprod"   # alphanumeric, 5–50 chars, globally unique
#     sku                           = "Standard"
#     admin_enabled                 = false
#     public_network_access_enabled = false
#   }
# }
#
# # -----------------------------------------------------------------------------
# # Log Analytics Workspaces
# # -----------------------------------------------------------------------------
# log_analytics_workspaces = {
#   main = { name = "jsh-002-Azure-INT-LogAnalytics-Bank-Prod", sku = "PerGB2018", retention_in_days = 90 }
# }
#
# # -----------------------------------------------------------------------------
# # Application Insights
# # -----------------------------------------------------------------------------
# application_insights = {
#   main = { name = "jsh-002-Azure-INT-AppInsights-Bank-Prod", application_type = "web", workspace_key = "main" }
# }
#
# # -----------------------------------------------------------------------------
# # User-Assigned Managed Identities
# # -----------------------------------------------------------------------------
# managed_identities = {
#   app = { name = "jsh-002-Azure-INT-MI-Bank-App" }
# }
#
# # -----------------------------------------------------------------------------
# # NAT Gateways
# # -----------------------------------------------------------------------------
# nat_gateways = {
#   main = { name = "jsh-002-Azure-INT-NAT-Bank-Prod", public_ip_name = "jsh-002-Azure-INT-PIP-NAT-Bank-Prod", idle_timeout_in_minutes = 10 }
# }
#
# # -----------------------------------------------------------------------------
# # Recovery Services Vaults – baseline: soft_delete_enabled = true
# # -----------------------------------------------------------------------------
# recovery_services_vaults = {
#   main = {
#     name                 = "jsh-002-Azure-INT-RSV-Bank-Prod"
#     sku                  = "Standard"
#     soft_delete_enabled  = true
#     # Security (optional): create_delete_lock = true. REMARK: set true for prod to prevent vault deletion
#   }
# }
#
# # -----------------------------------------------------------------------------
# # Private DNS Zones (optional; often auto-created with private endpoints)
# # -----------------------------------------------------------------------------
# private_dns_zones = {}
#
# # -----------------------------------------------------------------------------
# # Key Vault Secrets – use Key Vault references in App Service/Function; never store secrets in tfvars
# # -----------------------------------------------------------------------------
# key_vault_secrets = {
#   sql-connection = { secret_name = "SqlConnectionString", secret_value = "Server=...;Database=...;User Id=...;Password=...;", key_vault_key = "main", content_type = "text/plain" }
# }

# =============================================================================
# SECURITY OPTIONS REFERENCE (optional – enable via tfvars; see OPTIONAL_SECURITY_TFVARS.md)
# =============================================================================
# Top-level (NSG): jump_rdp_source_cidr, jump_ssh_source_cidr  → restrict RDP/SSH to VPN/bastion CIDR (TF_VAR or tfvars)
# vnets.<key>: subnets_allow_private_endpoint = ["private-endpoints"]  → PE subnet policies disabled (SECURITY_BASELINES 7.2)
# rg:                  create_lock, lock_level          → REMARK: lock for prod
# vms:                 os_disk_type, os_disk_size_gb, os_disk_name, computer_name, custom_data,
#                      encryption_at_host_enabled; boot_diagnostics_*; availability_zone
# storage_accounts:    blob_soft_delete_retention_days, container_soft_delete_retention_days,
#                      shared_key_access_disabled, network_rules, create_delete_lock
# keyvaults:           network_acls, create_delete_lock
# sql_servers:         azuread_administrator; databases: short_term_retention_days
# app_services:        connection_strings, health_check_path, https_only, identity_enabled, always_on, client_certificate_enabled
# recovery_services_vaults: create_delete_lock
