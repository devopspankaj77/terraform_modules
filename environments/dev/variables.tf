# -----------------------------------------------------------------------------
# Company-mandatory tags (must be set in tfvars or TF_VAR_*)
# -----------------------------------------------------------------------------
variable "created_by" {
  description = "Tag: Created By (company mandatory)"
  type        = string
}

variable "created_date" {
  description = "Tag: Created Date (company mandatory). Set to YYYY-MM-DD or leave unset to use apply date."
  type        = string
  default     = null
}

variable "environment" {
  description = "Tag: Environment (company mandatory)"
  type        = string
}

variable "requester" {
  description = "Tag: Requester (company mandatory)"
  type        = string
}

variable "ticket_reference" {
  description = "Tag: Ticket Reference (company mandatory)"
  type        = string
}

variable "project_name" {
  description = "Tag: Project Name (company mandatory)"
  type        = string
}

# Optional extra tags (e.g. Owner) can be set via additional_tags
variable "additional_tags" {
  description = "Optional tags merged with company-mandatory tags"
  type        = map(string)
  default     = {}
}

variable "rg" {
  type = object({
    name        = string
    location    = string
    create_lock = optional(bool, false)   # Optional: set true in tfvars for prod to prevent RG deletion
    lock_level  = optional(string, "CanNotDelete")
  })
}

variable "vnets" {
  type = map(object({
    name            = string
    address_space   = list(string)
    create_nsg      = bool
    nsg_per_subnet  = bool
    subnets = map(object({
      address_prefixes = list(string)
    }))
    # SECURITY_BASELINES 7.2: Subnet names used for private endpoints (get private_endpoint_network_policies = Disabled)
    subnets_allow_private_endpoint = optional(list(string), [])
  }))
  default = {}
}

variable "vms" {
  type = map(object({
    name                          = string
    vnet_key                      = string
    subnet_key                    = string
    admin_username                = string
    ssh_public_key                = optional(string)   # Linux: SSH key (optional if admin_password set). Use one or both.
    admin_password                = optional(string)   # Windows: required. Linux: optional; use for password login and/or with ssh_public_key (both allowed).
    size                          = string
    os_type                       = string
    public_ip                     = bool
    # Optional VM attributes; see OPTIONAL_SECURITY_TFVARS.md
    boot_diagnostics_enabled      = optional(bool, false)
    boot_diagnostics_storage_uri  = optional(string)
    availability_zone             = optional(string)
    os_disk_type                  = optional(string, "Standard_LRS")
    os_disk_size_gb               = optional(number, 128)
    os_disk_name                  = optional(string)
    delete_os_disk_on_termination = optional(bool, true)
    computer_name                 = optional(string)
    custom_data                   = optional(string)
    encryption_at_host_enabled    = optional(bool, false)
  }))
  default = {}
}

variable "nsg_rules" {
  type    = map(any)
  default = {}
}

# Optional: restrict SSH to jump box when jump is Linux (e.g. set TF_VAR_jump_ssh_source_cidr="x.x.x.x/32" in prod).
variable "jump_ssh_source_cidr" {
  description = "Override SSH source for subnet-jump NSG when jump VM is Linux; e.g. VPN/bastion CIDR. Leave null to use value from nsg_rules (e.g. * in dev)."
  type        = string
  default     = null
}

# Optional: restrict RDP to jump box when jump is Windows (e.g. set TF_VAR_jump_rdp_source_cidr="x.x.x.x/32" in prod).
variable "jump_rdp_source_cidr" {
  description = "Override RDP source for subnet-jump NSG when jump VM is Windows; e.g. VPN/bastion CIDR. Leave null to use value from nsg_rules (e.g. * in dev)."
  type        = string
  default     = null
}

variable "storage_accounts" {
  type    = map(any)
  default = {}
}

variable "keyvaults" {
  type    = map(any)
  default = {}
}

# -----------------------------------------------------------------------------
# Private Endpoints – scalable map; one entry per PE. Supports all PaaS types below.
# target_type: storage | keyvault | sql | mysql | redis | acr | app_service
# subresource_name: e.g. blob, vault, sqlServer, mysqlServer, redisCache, registry, sites
# See README or comment in dev.tfvars for per-service subresource names.
# -----------------------------------------------------------------------------
variable "private_endpoints" {
  type = map(object({
    name             = string
    target_type      = string   # storage, keyvault, sql, mysql, redis, acr, app_service
    target_key       = string   # key into storage_accounts, keyvaults, sql_servers, etc.
    vnet_key         = string
    subnet_key       = string
    subresource_name = string   # blob/file/queue/table, vault, sqlServer, mysqlServer, redisCache, registry, sites
  }))
  default = {}
}

variable "bastions" {
  description = "Azure Bastion Hosts"
  type = map(object({
    name               = string
    public_ip_name     = string
    vnet_key           = string
    subnet_key         = string # must be AzureBastionSubnet
    sku                = optional(string, "Standard")
    scale_units        = optional(number, 2)
    copy_paste_enabled = optional(bool, true)
    file_copy_enabled  = optional(bool, false)
    tunneling_enabled  = optional(bool, false)
  }))
  default = {}
}

variable "ssh_public_key" {
  description = "Default SSH public key if not provided per VM (required for Linux VMs)"
  type        = string
  default     = null
}

variable "jump_admin_password" {
  description = "Admin password for Windows jump VM when vm-jump uses os_type = 'windows'. Set via TF_VAR_jump_admin_password; do not commit in tfvars."
  type        = string
  sensitive   = true
  default     = null
}

# -----------------------------------------------------------------------------
# SQL Servers (map: key -> server config)
# Passwords: use TF_VAR_ or Key Vault; do not commit real values in tfvars.
# -----------------------------------------------------------------------------
variable "sql_servers" {
  type      = map(object({
    server_name    = string
    admin_username = string
    admin_password = string
    sql_version    = optional(string, "12.0")
    min_tls_version = optional(string, "1.2")
    firewall_rules = optional(map(object({
      start_ip_address = string
      end_ip_address   = string
    })), {})
    databases = optional(map(object({
      collation    = optional(string)
      license_type = optional(string)
      max_size_gb  = optional(number)
      sku_name     = optional(string)
      zone_redundant = optional(bool)
    })), {})
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Azure Cache for Redis (map: key -> cache config)
# -----------------------------------------------------------------------------
variable "redis_caches" {
  type = map(object({
    name               = string
    capacity           = optional(number, 0)
    family             = optional(string, "C")
    sku_name           = optional(string, "Basic")
    non_ssl_port_enabled = optional(bool, false)
    minimum_tls_version = optional(string, "1.2")
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# MySQL Flexible Servers (map: key -> server config)
# Passwords: use TF_VAR_ or Key Vault; do not commit real values in tfvars.
# -----------------------------------------------------------------------------
variable "mysql_servers" {
  type = map(object({
    name                    = string
    administrator_login     = string
    administrator_password  = string
    sku_name              = optional(string, "GP_Standard_D2ds_v4")
    mysql_version         = optional(string, "8.0.21")
    storage_size_gb       = optional(number, 20)
    backup_retention_days = optional(number, 7)
    databases             = optional(map(any), {})
    firewall_rules        = optional(map(object({
      start_ip_address = string
      end_ip_address   = string
    })), {})
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# App Services (map: key -> app config; each creates its own plan)
# -----------------------------------------------------------------------------
variable "app_services" {
  type = map(object({
    name                    = string
    plan_name               = string
    os_type                 = optional(string, "Linux")
    sku_name                = optional(string, "B1")
    app_settings            = optional(map(string), {})
    connection_strings      = optional(map(object({ type = string, value = string })), {})
    health_check_path       = optional(string)
    https_only              = optional(bool, true)
    identity_enabled        = optional(bool, true)
    always_on               = optional(bool)
    client_certificate_enabled = optional(bool, false)
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Function Apps (map: key -> function config; can use existing storage key)
# -----------------------------------------------------------------------------
variable "function_apps" {
  type = map(object({
    name                        = string
    plan_name                   = string
    sku_name                    = optional(string, "Y1")
    storage_account_key         = optional(string) # use existing from storage_accounts
    create_storage_account      = optional(bool, true) # if true, create dedicated SA
    app_settings                = optional(map(string), {})
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Logic Apps Standard (map: key -> logic app config)
# -----------------------------------------------------------------------------
variable "logic_apps" {
  type = map(object({
    name                 = string
    app_service_plan_key = string  # key into app_services for plan ID
    storage_account_key  = string  # key into storage_accounts
    app_settings         = optional(map(string), {})
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# API Management (map: key -> APIM config)
# -----------------------------------------------------------------------------
variable "api_managements" {
  type = map(object({
    name           = string
    publisher_name = string
    publisher_email = string
    sku_name       = optional(string, "Developer")
    vnet_key       = optional(string)
    subnet_key     = optional(string)
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# AKS Clusters (map: key -> cluster config)
# -----------------------------------------------------------------------------
variable "aks_clusters" {
  type = map(object({
    name                         = string
    dns_prefix                   = string
    vnet_key                     = string
    subnet_key                   = string
    kubernetes_version           = optional(string)
    default_node_pool_vm_size    = optional(string, "Standard_DS2_v2")
    default_node_pool_node_count = optional(number, 1)
    default_node_pool_enable_auto_scaling = optional(bool, false)
    default_node_pool_min_count  = optional(number, 1)
    default_node_pool_max_count  = optional(number, 3)
    enable_azure_rbac            = optional(bool, false)
    network_plugin               = optional(string, "kubenet")
    user_node_pools              = optional(map(object({
      vm_size             = string
      node_count          = number
      enable_auto_scaling = optional(bool, false)
      min_count           = optional(number)
      max_count           = optional(number)
      mode                = optional(string, "User")
    })), {})
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Container Registries (map: key -> ACR config)
# -----------------------------------------------------------------------------
variable "registries" {
  type = map(object({
    name                = string
    sku                 = optional(string, "Basic")
    admin_enabled       = optional(bool, false)
    public_network_access_enabled = optional(bool, true)
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Log Analytics Workspaces (monitoring – central logs)
# -----------------------------------------------------------------------------
variable "log_analytics_workspaces" {
  type = map(object({
    name              = string
    sku               = optional(string, "PerGB2018")
    retention_in_days  = optional(number, 30)
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Application Insights (app telemetry; optional workspace_id from log_analytics)
# -----------------------------------------------------------------------------
variable "application_insights" {
  type = map(object({
    name             = string
    application_type = optional(string, "web")
    workspace_key    = optional(string) # key into log_analytics_workspaces for workspace_id
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# User-Assigned Managed Identities (for apps, AKS, Key Vault access without keys)
# -----------------------------------------------------------------------------
variable "managed_identities" {
  type = map(object({
    name = string
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# NAT Gateways (stable outbound IP; associate to subnet via subnet nat_gateway_id)
# -----------------------------------------------------------------------------
variable "nat_gateways" {
  type = map(object({
    name                = string
    public_ip_name      = string
    idle_timeout_in_minutes = optional(number, 10)
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Recovery Services Vaults (VM backup, Azure Backup)
# -----------------------------------------------------------------------------
variable "recovery_services_vaults" {
  type = map(object({
    name               = string
    sku                = optional(string, "Standard")
    soft_delete_enabled = optional(bool, true)
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Private DNS Zones – scalable map: add one entry per zone; each zone is linked to listed VNets.
# Use for extra zones not auto-created by private endpoints (PE zones for blob, vault, sql, mysql, redis, acr, webapp are created inline in main.tf when a PE of that type exists). Add here any other privatelink or custom zone (e.g. privatelink.postgres.database.azure.com, or your own zone name).
# -----------------------------------------------------------------------------
variable "private_dns_zones" {
  type = map(object({
    zone_name            = string   # e.g. privatelink.database.windows.net, privatelink.azurecr.io
    vnet_keys            = list(string) # keys into vnets for linking
    registration_enabled = optional(bool, false)
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Key Vault Secrets – scalable map: add one entry per secret; use for SQL, MySQL, API keys, etc.
# key_vault_key = key into keyvaults (e.g. "main"). Use TF_VAR_* or sensitive variables for secret_value.
# content_type  = optional (e.g. "text/plain", "application/json"). Multiple Key Vaults supported.
# -----------------------------------------------------------------------------
variable "key_vault_secrets" {
  type = map(object({
    secret_name   = string
    secret_value  = string   # use TF_VAR or sensitive variable; do not commit real values
    key_vault_key = string   # key into keyvaults (e.g. "main")
    content_type  = optional(string)
  }))
  default = {}
}

variable "secret_name" {
  description = "Example secret name for Key Vault Secret module"
  type        = string
  default     = "example-secret"  
}

variable "secret_value" {
  description = "Example secret value for Key Vault Secret module (use TF_VAR_ or sensitive variable; do not commit real secrets in tfvars)"
  type        = string
  default     = "example-secret-value"
}