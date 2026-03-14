# =============================================================================
# Production: App on VM + SQL Server + Redis — Full security baseline
# =============================================================================
# Same as prod-vm-app.tfvars but adds Azure SQL Database and Azure Cache for Redis
# (and their private endpoints) for VM apps that need relational DB and cache.
#
# Usage:
#   cd environments/prod
#   terraform plan -var-file=prod-vm-app-sql-redis.tfvars
#   terraform apply -var-file=prod-vm-app-sql-redis.tfvars
#
# Pre-requisites:
#   - Set TF_VAR_jump_admin_password, TF_VAR_ssh_public_key (if Linux app VM).
#   - Set TF_VAR_jump_rdp_source_cidr for RDP restriction.
#   - Set SQL admin password: use -var 'sql_servers={"main"={...}}' with admin_password,
#     or a separate secret .tfvars (e.g. prod-vm-app-sql-redis.secret.tfvars) that sets
#     sql_servers.main.admin_password; do not commit secrets.
#
# Security baseline: SECURITY_BASELINES.md, RESOURCE_CONTROLS_SHEET.md.
# =============================================================================

# -----------------------------------------------------------------------------
# Company-mandatory tags (audit, chargeback, compliance)
# -----------------------------------------------------------------------------
created_by       = "Platform"
created_date     = "2026-03-13"
environment      = "prod"
requester        = "Application Team"
ticket_reference = "CHG-VMAPP-SQL-001"
project_name     = "Bank-App-On-VM-SQL-Redis"

additional_tags = {
  Owner               = "platform-team"
  CostCenter          = "prod"
  DataClassification  = "Confidential"
}

# -----------------------------------------------------------------------------
# Resource Group
# Why: Logical container for all resources; lock prevents accidental deletion in prod.
# -----------------------------------------------------------------------------
rg = {
  name        = "rg-jsh-project-terraform-prod-eastus"
  location    = "eastus"
  create_lock = true
  lock_level  = "CanNotDelete"
}

# -----------------------------------------------------------------------------
# Virtual Network and subnets
# Why: Isolated app/data/jump/PE subnets; NSG per subnet; PE subnet for private link.
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
      private-endpoints = {
        address_prefixes = ["10.2.100.0/24"]
      }
      AzureBastionSubnet = {
        address_prefixes = ["10.2.5.0/26"]
      }
    }
    subnets_allow_private_endpoint = ["private-endpoints"]
  }
}

# -----------------------------------------------------------------------------
# Virtual Machines: app VM (Linux) + jump VM (Windows)
# Why: App VM runs the app; jump for management; no public IP; access via Bastion.
# -----------------------------------------------------------------------------
vms = {
  vm-app = {
    name           = "jsh-002-Azure-LIN-INT-Bank-App"
    vnet_key       = "main"
    subnet_key     = "subnet-app"
    admin_username = "azureuser"
    ssh_public_key = null
    size           = "Standard_B2s"
    os_type        = "linux"
    public_ip      = false
    boot_diagnostics_enabled = true
    availability_zone        = "1"
    os_disk_type             = "Premium_LRS"
    encryption_at_host_enabled = false
  }

  vm-jump = {
    name           = "jsh-002-Azure-WIN-INT-Bank-Jump"
    vnet_key       = "main"
    subnet_key     = "subnet-jump"
    admin_username = "azureadmin"
    admin_password = null
    size           = "Standard_B2s"
    os_type        = "windows"
    public_ip      = false
    boot_diagnostics_enabled = true
    availability_zone        = "2"
  }
}

# -----------------------------------------------------------------------------
# NSG rules (deny-by-default)
# Why: Least-privilege; app/data/jump/PE rules; includes Redis (6380) for PE subnet when using Redis PE.
# -----------------------------------------------------------------------------
nsg_rules = {
  subnet-app = {
    allow_https         = { priority = 110, direction = "Inbound", access = "Allow", protocol = "Tcp", destination_port_range = "443", source_address_prefix = "10.2.3.0/24", destination_address_prefix = "*" }
    allow_ssh_from_jump = { priority = 120, direction = "Inbound", access = "Allow", protocol = "Tcp", destination_port_range = "22", source_address_prefix = "10.2.3.0/24", destination_address_prefix = "*" }
  }
  subnet-data = {
    allow_sql_from_app  = { priority = 100, direction = "Inbound", access = "Allow", protocol = "Tcp", destination_port_range = "1433", source_address_prefix = "10.2.1.0/24", destination_address_prefix = "*" }
    allow_sql_from_jump = { priority = 110, direction = "Inbound", access = "Allow", protocol = "Tcp", destination_port_range = "1433", source_address_prefix = "10.2.3.0/24", destination_address_prefix = "*" }
  }
  subnet-jump = {
    allow_rdp = { priority = 100, direction = "Inbound", access = "Allow", protocol = "Tcp", destination_port_range = "3389", source_address_prefix = "10.255.255.254/32", destination_address_prefix = "*" }
  }
  private-endpoints = {
    allow_https_from_vnet  = { priority = 100, direction = "Inbound", access = "Allow", protocol = "Tcp", destination_port_range = "443", source_address_prefix = "10.2.0.0/16", destination_address_prefix = "*" }
    allow_sql_from_vnet   = { priority = 110, direction = "Inbound", access = "Allow", protocol = "Tcp", destination_port_range = "1433", source_address_prefix = "10.2.0.0/16", destination_address_prefix = "*" }
    allow_redis_from_vnet = { priority = 120, direction = "Inbound", access = "Allow", protocol = "Tcp", destination_port_range = "6380", source_address_prefix = "10.2.0.0/16", destination_address_prefix = "*" }
  }
}

# jump_rdp_source_cidr: set TF_VAR_jump_rdp_source_cidr to your VPN/bastion CIDR.

# -----------------------------------------------------------------------------
# Storage Account (GZRS, TLS 1.2, versioning, soft delete, lock — see prod-vm-app.tfvars for attribute “why”)
# -----------------------------------------------------------------------------
storage_accounts = {
  main = {
    name                    = "jsh002stgvmappprod"
    account_tier            = "Standard"
    replication_type        = "GZRS"
    account_kind            = "StorageV2"
    min_tls_version         = "TLS1_2"
    enable_blob_versioning  = true
    containers              = { data = { access_type = "private" } }
    blob_soft_delete_retention_days    = 30
    container_soft_delete_retention_days = 30
    create_delete_lock                 = true
  }
}

# -----------------------------------------------------------------------------
# Key Vault (RBAC only, 90d soft delete, purge protection, lock — see prod-vm-app.tfvars for “why”)
# -----------------------------------------------------------------------------
keyvaults = {
  main = {
    name                       = "jsh002kvvmapprodeus1"
    sku_name                    = "standard"
    rbac_authorization_enabled  = true
    purge_protection_enabled    = true
    soft_delete_retention_days  = 90
    create_delete_lock          = true
  }
}

# -----------------------------------------------------------------------------
# Private Endpoints: Storage, Key Vault, SQL, Redis
# Why: All PaaS traffic over private IP; no public endpoints. Private DNS zones (main.tf) resolve to private IPs.
#   sql_pe  → App/jump connect to SQL via private link (no public SQL firewall).
#   redis_pe → App connects to Redis over TLS on private link (port 6380).
# -----------------------------------------------------------------------------
private_endpoints = {
  storage_pe = { name = "jsh-002-Azure-INT-PE-Stg-VmApp", target_type = "storage", target_key = "main", vnet_key = "main", subnet_key = "private-endpoints", subresource_name = "blob" }
  kv_pe      = { name = "jsh-002-Azure-INT-PE-KV-VmApp", target_type = "keyvault", target_key = "main", vnet_key = "main", subnet_key = "private-endpoints", subresource_name = "vault" }
  sql_pe     = { name = "jsh-002-Azure-INT-PE-SQL-VmApp", target_type = "sql", target_key = "main", vnet_key = "main", subnet_key = "private-endpoints", subresource_name = "sqlServer" }
  redis_pe   = { name = "jsh-002-Azure-INT-PE-Redis-VmApp", target_type = "redis", target_key = "main", vnet_key = "main", subnet_key = "private-endpoints", subresource_name = "redisCache" }
}

# -----------------------------------------------------------------------------
# Azure Bastion (RDP/SSH to jump without public IPs on VMs)
# -----------------------------------------------------------------------------
bastions = {
  main = {
    name           = "jsh-002-Azure-INT-Bastion-VmApp-Prod"
    public_ip_name = "jsh-002-Azure-INT-PIP-Bastion-VmApp"
    vnet_key       = "main"
    subnet_key     = "AzureBastionSubnet"
    sku            = "Standard"
    scale_units    = 2
  }
}

# -----------------------------------------------------------------------------
# SQL Server (relational DB for the app)
# Why: App on VM connects to SQL for persistent data; private endpoint so no public SQL exposure.
# Attribute-level rationale (security baseline):
#   min_tls_version = "1.2"   → Enforce TLS 1.2+ for connections; disables older protocols.
#   firewall_rules = {}      → With PE only, no public firewall rules needed; access only via private link.
#   databases                 → S0 for prod; short_term_retention_days 7–35 for PITR (compliance).
# Set admin_password via a secret tfvars or -var; never commit. Optionally add azuread_administrator for MFA.
# -----------------------------------------------------------------------------
sql_servers = {
  main = {
    server_name     = "jsh002sqlvmappprod"
    admin_username  = "sqladmin"
    admin_password  = ""   # REQUIRED: set via -var or secret tfvars (e.g. prod-vm-app-sql-redis.secret.tfvars); never commit
    min_tls_version = "1.2"
    firewall_rules  = {}
    databases       = {
      main = { sku_name = "S0", max_size_gb = 250, short_term_retention_days = 7 }
    }
  }
}

# -----------------------------------------------------------------------------
# Redis Cache (session/cache for the app)
# Why: App uses Redis for session store or cache; private endpoint so no public Redis exposure.
# Attribute-level rationale (security baseline):
#   non_ssl_port_enabled = false  → Disable port 6379; force TLS (6380) only (baseline).
#   minimum_tls_version  = "1.2"   → Enforce TLS 1.2+ for encrypted connections.
# -----------------------------------------------------------------------------
redis_caches = {
  main = {
    name                 = "jsh002redvmappprod"
    capacity             = 1
    family               = "C"
    sku_name             = "Standard"
    non_ssl_port_enabled = false
    minimum_tls_version  = "1.2"
  }
}