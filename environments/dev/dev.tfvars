# =============================================================================
# Dev Environment - Enterprise Ready
# Active: RG, VNet, subnets only. Uncomment vms and nsg_rules (and other blocks below) to create VMs, NSG rules, storage, KV, etc.
# Optional resource maps (vms, nsg_rules, storage_accounts, keyvaults, etc.) default to {} in variables.tf.
# Only set a variable in this file when you want to create those resources; no need to write = {}.
# Some resources may require quota (App Service, Function) or different region (SQL, MySQL); see README.
# Company-mandatory tags (must be set):
#   Created By, Created Date, Environment, Requester, Ticket Reference, Project Name
#
# Naming convention (Internal project – treat as INT):
#   VM:        jsr-002-Azure-LIN-INT-IT-Sonar
#   Web App:   jsr-055-Azure-INT-Web-App-RAT-QA
#   Client:    jsr-051-Azure-CLT-Web-App-Cook-Medical, jsr-045-Azure-WIN-CLI-Starting-Point
#   Pattern:  jsr-<nnn>-Azure-<INT|CLT>-<ResourceType>-<Workload>
#   This env: INT, instance 002, workload Bank-Dev. Storage/ACR: no hyphens (Azure limit).
# =============================================================================

# -----------------------------------------------------------------------------
# Company-mandatory tags
# -----------------------------------------------------------------------------
created_by       = "Pankaj"
created_date     = "2026-03-11"   # Match deployed tags; set to null to use apply date (YYYY-MM-DD) for new deployments.
environment      = "dev"
requester        = "Application Team"
ticket_reference = "INC-12345"
project_name     = "Banking-App"

# Optional: add extra tags (e.g. Owner) via additional_tags
additional_tags = { "Owner" = "platform-team" }

# -----------------------------------------------------------------------------
# Resource Group (with proper tagging via common_tags in main.tf)
# Security options (optional – set in tfvars; see REMARKS below):
#   create_lock = true   → CanNotDelete management lock (REMARK: recommended for prod; prevents accidental RG deletion)
#   lock_level  = "CanNotDelete" | "ReadOnly"
# -----------------------------------------------------------------------------
rg = {
  name     = "rg-jsr-project-terraform-dev-eastus"
  location = "eastus"
  # create_lock = false   # REMARK: set true for prod to prevent RG deletion
  # lock_level  = "CanNotDelete"
}

# -----------------------------------------------------------------------------
# Virtual Network (active – includes subnets)
# -----------------------------------------------------------------------------
vnets = {
  main = {
    name            = "jsr-002-Azure-INT-VNet-Bank-Dev"
    address_space   = ["10.10.0.0/16"]
    create_nsg      = true
    nsg_per_subnet  = true

    subnets = {
      subnet-app = {
        address_prefixes = ["10.10.1.0/24"]
      }

      subnet-data = {
        address_prefixes = ["10.10.2.0/24"]
      }

      subnet-jump = {
        address_prefixes = ["10.10.3.0/24"]
      }

      # AKS: /23 recommended for Azure CNI (nodes + pods); or sufficient for node scale-out with kubenet/overlay
      subnet-aks = {
        address_prefixes = ["10.10.6.0/23"]
      }

      # Dedicated subnet for private endpoints (PaaS); no VMs in this subnet
      subnet-pe = {
        address_prefixes = ["10.10.100.0/24"]
      }

      # Required for Azure Bastion (must be named exactly AzureBastionSubnet; /26 or larger recommended)
      AzureBastionSubnet = {
        address_prefixes = ["10.10.5.0/26"]
      }
    }
    # SECURITY_BASELINES 7.2: Dedicated PE subnet gets private_endpoint_network_policies = Disabled
    subnets_allow_private_endpoint = ["subnet-pe"]
  }
}

# -----------------------------------------------------------------------------
# Virtual Machines – comment out block above and uncomment below to create jump + app VMs
# Linux: login via ssh_public_key only, admin_password only, or BOTH (set both for SSH + password).
# -----------------------------------------------------------------------------
vms = {
  vm-app = {
    name           = "jsr-002-Azure-LIN-INT-Bank-App"
    vnet_key       = "main"
    subnet_key     = "subnet-app"
    admin_username = "azureuser"
    ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC0ysfBZDkxNXOMcWMNXrGQNTbC8V2n6Fa0Is+caJL7J5KDgCN31XVibqtQC11OE3+jhU/XTZ1Kr3nSGAlWZoNm85ViGAjfkuJjvBFpLDrTMoIiueyiFYr/skRGJ2+U9Ml9LcUaqLgw3R0Pevr/DDwwbf0Q9rwmNuzOiZAhEoic/RWLJzYEb1dBeHN/pIo3l+1XpZjpfA/CKSeSz2BGDhawp46H41FkvQGGwTyZkKXW4HdCOEyEtjt/PFMM6tWViKCo+5ujCzUbotQVtfGJsEmkqPVC0JVZIERzsQmycy837Fwg6gk9lCCvcWdTUSue+hU+cuR7TVHthGeidUuRAzWh+av1X7009VONIbm17124kvsnVCDRhk53Kbf6z6BVd/DpvE78MVXikZuW/KmYVVCl/5r30+nusZbBUpENWtkE1fjyn0diqs1PnAyeTZVziKkbhsD1ViL5rd/k7AynGKbQoV1Kw99b9mVoEhOiPJ/Kg6yoDtDpXK29M0hB6vlz6a1O7eZ4aZtBqsokotCW/Ctc0RxItLZydN7mI08CSLErWs9f4zy8HE/5FIfWB8JVzc6Mq1wine+SRbXjLIJtmITGzUpI52LgxtVq4nNf+5E2orZjQ+pNSAzJ4lsRy0+KaM239/wYa0OjWwa3wVNbdv3I9QCBHBqf0g6r3g2itJEYTw== azureuser@myproject"
    admin_password = "YourSecureP@ssw0rd!"   # optional: add for password login or use BOTH ssh + password
    size           = "Standard_B2s"
    os_type        = "linux"
    public_ip      = false
  }

  vm-jump = {
    name           = "jsr-002-Azure-WIN-INT-Bank-Jump"
    vnet_key       = "main"
    subnet_key     = "subnet-jump"
    admin_username = "azureadmin"
    admin_password = "P@ssw@rd@12345!"
    size           = "Standard_B2s"
    os_type        = "windows"
    public_ip      = true
  }
}
# (vms defaults to {} in variables.tf; uncomment block above to create VMs)

# -----------------------------------------------------------------------------
# NSG Rules – uncomment when you create VMs or need rules on subnets
# -----------------------------------------------------------------------------
nsg_rules = {
  subnet-app = {
    allow_https         = { priority = 110, direction = "Inbound", access = "Allow", protocol = "Tcp", destination_port_range = "443", source_address_prefix = "10.10.3.0/24", destination_address_prefix = "*" }
    allow_ssh_from_jump = { priority = 120, direction = "Inbound", access = "Allow", protocol = "Tcp", destination_port_range = "22", source_address_prefix = "10.10.3.0/24", destination_address_prefix = "*" }
  }
  subnet-data = {
    allow_sql_from_app  = { priority = 100, direction = "Inbound", access = "Allow", protocol = "Tcp", destination_port_range = "1433", source_address_prefix = "10.10.1.0/24", destination_address_prefix = "*" }
    allow_sql_from_jump = { priority = 110, direction = "Inbound", access = "Allow", protocol = "Tcp", destination_port_range = "1433", source_address_prefix = "10.10.3.0/24", destination_address_prefix = "*" }
  }
  subnet-jump = {
    allow_rdp = { priority = 100, direction = "Inbound", access = "Allow", protocol = "Tcp", destination_port_range = "3389", source_address_prefix = "*", destination_address_prefix = "*" }
  }
  subnet-aks = {
    allow_https_from_jump = { priority = 100, direction = "Inbound", access = "Allow", protocol = "Tcp", destination_port_range = "443", source_address_prefix = "10.10.3.0/24", destination_address_prefix = "*" }
    allow_ssh_from_jump   = { priority = 110, direction = "Inbound", access = "Allow", protocol = "Tcp", destination_port_range = "22", source_address_prefix = "10.10.3.0/24", destination_address_prefix = "*" }
  }
  subnet-pe = {
    allow_https_from_vnet  = { priority = 100, direction = "Inbound", access = "Allow", protocol = "Tcp", destination_port_range = "443", source_address_prefix = "10.10.0.0/16", destination_address_prefix = "*" }
    allow_sql_from_vnet   = { priority = 110, direction = "Inbound", access = "Allow", protocol = "Tcp", destination_port_range = "1433", source_address_prefix = "10.10.0.0/16", destination_address_prefix = "*" }
    allow_redis_from_vnet = { priority = 120, direction = "Inbound", access = "Allow", protocol = "Tcp", destination_port_range = "6380", source_address_prefix = "10.10.0.0/16", destination_address_prefix = "*" }
  }
}
# (nsg_rules defaults to {}; uncomment block above to add rules)

# # -----------------------------------------------------------------------------
# # Storage Account
# # -----------------------------------------------------------------------------
# storage_accounts = {
#   main = {
#     name = "jsr002stgbankdev"
#     account_tier = "Standard"
#     replication_type = "ZRS"
#     account_kind = "StorageV2"
#     min_tls_version = "TLS1_2"
#     enable_blob_versioning = true
#     containers = { data = { access_type = "private" } }
#     # Security (optional) – uncomment to enable:
#     # blob_soft_delete_retention_days   = 7
#     # container_soft_delete_retention_days = 7
#     # shared_key_access_disabled        = false   # enable via Portal/Policy if provider unsupported
#     # create_delete_lock                = false
#     # network_rules = { default_action = "Deny", bypass = ["AzureServices"], ip_rules = [], virtual_network_subnet_ids = [] }
#     # REMARK: soft delete 7d dev/30d prod; create_delete_lock = true for prod; network_rules when not PE-only
#   }
# }
#
# # -----------------------------------------------------------------------------
# # Azure Key Vault
# # -----------------------------------------------------------------------------
# keyvaults = {
#   main = {
#     name = "jsr002-kv-bank-dev-eus1"
#     sku_name = "standard"
#     rbac_authorization_enabled = true
#     purge_protection_enabled = true
#     soft_delete_retention_days = 30
#     # Security (optional) – uncomment to enable:
#     # network_acls = { default_action = "Deny", bypass = "AzureServices", ip_rules = [], virtual_network_subnet_ids = [] }
#     # create_delete_lock = false
#     # REMARK: network_acls when not PE-only; create_delete_lock = true for prod
#   }
# }
#
# # -----------------------------------------------------------------------------
# # Private Endpoints
# # -----------------------------------------------------------------------------
# private_endpoints = {
#   storage_pe = { name = "jsr-002-Azure-INT-PE-Stg-Bank", target_type = "storage", target_key = "main", vnet_key = "main", subnet_key = "subnet-pe", subresource_name = "blob" }
#   kv_pe      = { name = "jsr-002-Azure-INT-PE-KV-Bank", target_type = "keyvault", target_key = "main", vnet_key = "main", subnet_key = "subnet-pe", subresource_name = "vault" }
#   sql_pe     = { name = "jsr-002-Azure-INT-PE-SQL-Bank", target_type = "sql", target_key = "main", vnet_key = "main", subnet_key = "subnet-pe", subresource_name = "sqlServer" }
#   mysql_pe   = { name = "jsr-002-Azure-INT-PE-MySQL-Bank", target_type = "mysql", target_key = "main", vnet_key = "main", subnet_key = "subnet-pe", subresource_name = "mysqlServer" }
#   redis_pe   = { name = "jsr-002-Azure-INT-PE-Redis-Bank", target_type = "redis", target_key = "main", vnet_key = "main", subnet_key = "subnet-pe", subresource_name = "redisCache" }
#   acr_pe     = { name = "jsr-002-Azure-INT-PE-ACR-Bank", target_type = "acr", target_key = "main", vnet_key = "main", subnet_key = "subnet-pe", subresource_name = "registry" }
#   app_pe     = { name = "jsr-002-Azure-INT-PE-WebApp-Bank", target_type = "app_service", target_key = "main", vnet_key = "main", subnet_key = "subnet-pe", subresource_name = "sites" }
# }
#
# # -----------------------------------------------------------------------------
# # Azure Bastion
# # -----------------------------------------------------------------------------
# bastions = {
#   main = { name = "jsr-002-Azure-INT-Bastion-Bank-Dev", public_ip_name = "jsr-002-Azure-INT-PIP-Bastion-Bank-Dev", vnet_key = "main", subnet_key = "AzureBastionSubnet", sku = "Standard", scale_units = 2 }
# }
#
# # -----------------------------------------------------------------------------
# # SQL Servers
# # -----------------------------------------------------------------------------
# sql_servers = {
#   main = {
#     server_name = "jsr002-sql-bank-dev-eus1"
#     admin_username = "sqladmin"
#     admin_password = "DevP@ssw0rd123!"
#     firewall_rules = { allow_azure = { start_ip_address = "0.0.0.0", end_ip_address = "0.0.0.0" } }
#     databases = { appdb = { sku_name = "Basic", max_size_gb = 2 } }   # or add short_term_retention_days = 7 (7–35) per db
#     # Security (optional) – uncomment to enable:
#     # azuread_administrator = { login = "sql-admins", object_id = "<azure-ad-group-object-id>", tenant_id = null }
#     # extended_auditing_policy: use azurerm_mssql_server_extended_auditing_policy in env when needed
#     # REMARK: Azure AD admin for MFA; short_term_retention_days 7–35 per policy; auditing via separate resource
#   }
# }
#
# # -----------------------------------------------------------------------------
# # Redis Caches
# # -----------------------------------------------------------------------------
# redis_caches = {
#   main = { name = "jsr002-redis-bank-dev-eus1", capacity = 0, family = "C", sku_name = "Basic" }
# }
#
# # -----------------------------------------------------------------------------
# # MySQL Flexible Servers
# # -----------------------------------------------------------------------------
# mysql_servers = {
#   main = {
#     name = "jsr002-mysql-bank-dev-eus1"
#     administrator_login = "mysqladmin"
#     administrator_password = "DevP@ssw0rd123!"
#     sku_name = "GP_Standard_D2ds_v4"
#     storage_size_gb = 20
#     backup_retention_days = 7
#     databases = { appdb = {} }
#     firewall_rules = {}
#   }
# }
#
# # -----------------------------------------------------------------------------
# # App Services (Enterprise – fully usable with connection strings, health check, app_settings)
# # Requires: names/plan_name globally unique. For Logic Apps: use this plan via app_service_plan_key = "main".
# # Optional: connection_strings (SQL, Redis, Custom); health_check_path; app_settings (incl. Key Vault refs).
# # -----------------------------------------------------------------------------
# app_services = {
#   main = {
#     name      = "jsr-002-Azure-INT-Web-App-Bank-Dev"
#     plan_name = "jsr-002-Azure-INT-App-Srv-Plan-Bank-Dev"
#     os_type   = "Linux"
#     sku_name  = "B1"
#     app_settings = {}
#     # Optional: connection strings (use Key Vault ref in prod: @Mjsrosoft.KeyVault(SecretUri=...))
#     # connection_strings = {
#     #   DefaultConnection = { type = "SQLAzure", value = "Server=...;Database=...;User Id=...;Password=...;" }
#     #   Redis             = { type = "Custom", value = "redis-host:6380,password=...,ssl=True" }
#     # }
#     # Optional: health check path for load balancer / availability (e.g. /health)
#     # health_check_path = "/health"
#     # Security (optional) – defaults: https_only = true, identity_enabled = true
#     # https_only                  = true
#     # identity_enabled            = true
#     # always_on                   = true   # set true for prod when SKU supports it (B1 has limited always_on)
#     # client_certificate_enabled  = false  # mutual TLS; requires provider support
#   }
# }
# (app_services defaults to {}; uncomment block above to create App Service)

# # -----------------------------------------------------------------------------
# # Function Apps (Enterprise)
# # Requires: storage_accounts with key referenced by storage_account_key, or set create_storage_account = true for dedicated SA.
# # SKU: Y1 = Consumption (dev); EP1, P1v2 = Dedicated (prod). Name/plan_name: globally unique, alphanumeric/hyphens.
# # -----------------------------------------------------------------------------
# function_apps = {
#   main = {
#     name                = "jsr-002-Azure-INT-Func-App-Bank-Dev"
#     plan_name           = "jsr-002-Azure-INT-Func-Plan-Bank-Dev"
#     sku_name            = "Y1"   # Consumption; use EP1/P1v2 for dedicated (prod)
#     storage_account_key = "main" # Key into storage_accounts; use existing storage for AzureWebJobsStorage
#     # create_storage_account = false  # true = create dedicated SA for this function app (when not using storage_account_key)
#     app_settings = {}
#     # Optional app_settings examples (secrets via Key Vault ref in prod):
#     # app_settings = { "FUNCTIONS_WORKER_RUNTIME" = "node", "WEBSITE_RUN_FROM_PACKAGE" = "1" }
#   }
# }
#
# # -----------------------------------------------------------------------------
# # Logic Apps Standard (Enterprise)
# # Requires: app_services (with plan) and storage_accounts; app_service_plan_key = key in app_services that holds the plan.
# # Logic App Standard runs on a dedicated App Service Plan (not Consumption). Use same plan as app_services or a dedicated plan.
# # -----------------------------------------------------------------------------
# logic_apps = {
#   main = {
#     name                 = "jsr-002-Azure-INT-Logic-App-Bank-Dev"
#     app_service_plan_key = "main"  # Key in app_services; that app's plan hosts this Logic App
#     storage_account_key  = "main"  # Key in storage_accounts; used for workflow state
#     app_settings         = {}
#     # Optional: app_settings = { "key" = "value" }
#   }
# }
#
# # -----------------------------------------------------------------------------
# # API Management (Enterprise)
# # Name: globally unique, 1–50 chars; use lowercase/hyphens (e.g. jsr002-apim-bank-dev-eus1). Publisher info required.
# # SKU: Developer_1 (dev), Consumption (pay-per-use), Basic/Standard/Premium (prod). VNet: optional for Standard/Premium.
# # -----------------------------------------------------------------------------
# api_managements = {
#   main = {
#     name             = "jsr002-apim-bank-dev-eus1"   # Globally unique; often no hyphens for APIM
#     publisher_name   = "Platform Team"
#     publisher_email  = "platform@contoso.com"
#     sku_name         = "Developer_1"   # Dev; use Standard or Premium for prod with VNet integration
#     # Optional: VNet integration (Standard/Premium). Requires vnet_key and subnet_key from vnets.
#     # vnet_key   = "main"
#     # subnet_key = "subnet-app"   # Dedicated subnet for APIM (e.g. subnet-apim); /27 or larger
#   }
# }
# (function_apps, logic_apps, api_managements default to {}; uncomment blocks above to create)

# # -----------------------------------------------------------------------------
# # AKS Clusters
# # -----------------------------------------------------------------------------
# aks_clusters = {
#   main = {
#     name = "jsr-002-Azure-INT-AKS-Bank-Dev"
#     dns_prefix = "jsr002aksbankdev"
#     vnet_key = "main"
#     subnet_key = "subnet-aks"
#     default_node_pool_node_count = 1
#     default_node_pool_vm_size = "Standard_F4s_v2"
#     default_node_pool_enable_auto_scaling = true
#     default_node_pool_min_count = 1
#     default_node_pool_max_count = 5
#     enable_azure_rbac = false
#   }
# }
#
# # -----------------------------------------------------------------------------
# # Container Registries
# # -----------------------------------------------------------------------------
# registries = {
#   main = { name = "acrjsr002intbankeus1", sku = "Basic", admin_enabled = false }
# }
#
# # -----------------------------------------------------------------------------
# # Log Analytics Workspaces
# # -----------------------------------------------------------------------------
# log_analytics_workspaces = {
#   main = { name = "jsr-002-Azure-INT-LogAnalytics-Bank-Dev", sku = "PerGB2018", retention_in_days = 30 }
# }
#
# # -----------------------------------------------------------------------------
# # Application Insights
# # -----------------------------------------------------------------------------
# application_insights = {
#   main = { name = "jsr-002-Azure-INT-AppInsights-Bank-Dev", application_type = "web", workspace_key = "main" }
# }
#
# # -----------------------------------------------------------------------------
# # User-Assigned Managed Identities
# # -----------------------------------------------------------------------------
# managed_identities = {
#   app = { name = "jsr-002-Azure-INT-MI-Bank-App" }
# }
#
# # -----------------------------------------------------------------------------
# # NAT Gateways
# # -----------------------------------------------------------------------------
# nat_gateways = {
#   main = { name = "jsr-002-Azure-INT-NAT-Bank-Dev", public_ip_name = "jsr-002-Azure-INT-PIP-NAT-Bank-Dev", idle_timeout_in_minutes = 10 }
# }
#
# # -----------------------------------------------------------------------------
# # Recovery Services Vaults
# # -----------------------------------------------------------------------------
# recovery_services_vaults = {
#   main = {
#     name = "jsr-002-Azure-INT-RSV-Bank-Dev"
#     sku = "Standard"
#     soft_delete_enabled = true
#     # Security (optional): create_delete_lock = false. REMARK: set true for prod to prevent vault deletion
#   }
# }
#
# # -----------------------------------------------------------------------------
# # Private DNS Zones
# # -----------------------------------------------------------------------------
# private_dns_zones = {}
#
# # -----------------------------------------------------------------------------
# # Key Vault Secrets
# # -----------------------------------------------------------------------------
# key_vault_secrets = {
#   sql-connection = { secret_name = "SqlConnectionString", secret_value = "Server=...;Database=...;User Id=...;Password=...;", key_vault_key = "main", content_type = "text/plain" }
# }
#
# =============================================================================
# SECURITY OPTIONS REFERENCE (optional – enable via tfvars; see OPTIONAL_SECURITY_TFVARS.md)
# =============================================================================
# Top-level (NSG):     jump_rdp_source_cidr, jump_ssh_source_cidr  → restrict RDP/SSH to VPN/bastion CIDR (TF_VAR or tfvars)
# vnets.<key>:        subnets_allow_private_endpoint = ["subnet-pe"]  → dedicated PE subnet; policies disabled (SECURITY_BASELINES 7.2)
# rg:                  create_lock, lock_level          → REMARK: lock for prod
# vms:                 os_disk_type, os_disk_size_gb, os_disk_name, computer_name, custom_data,
#                     encryption_at_host_enabled; boot_diagnostics_*; availability_zone
# storage_accounts:    blob_soft_delete_retention_days, container_soft_delete_retention_days,
#                     shared_key_access_disabled, network_rules, create_delete_lock
# keyvaults:           network_acls, create_delete_lock
# sql_servers:         azuread_administrator; databases: short_term_retention_days
# app_services:       connection_strings, health_check_path, https_only, identity_enabled, always_on, client_certificate_enabled
# recovery_services_vaults: create_delete_lock
