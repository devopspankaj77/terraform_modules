# =============================================================================
# Production Environment Variables — Same structure as dev for consistency
# =============================================================================
# Use the same variable names and map-based layout as dev (rg, vnets, vms,
# storage_accounts, keyvaults, etc.). Set prod-specific values in prod.tfvars
# per SECURITY_BASELINES.md (e.g. GZRS, RBAC-only KV, no 0.0.0.0/0 for RDP/SSH).
# =============================================================================

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

# Optional extra tags (e.g. Owner, CostCenter, DataClassification)
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
    name                         = string
    vnet_key                     = string
    subnet_key                   = string
    admin_username               = string
    ssh_public_key               = optional(string)
    admin_password               = optional(string)
    size                         = string
    os_type                      = string
    public_ip                    = bool
    # Optional VM attributes (align with dev; see OPTIONAL_SECURITY_TFVARS.md)
    boot_diagnostics_enabled     = optional(bool, false)
    boot_diagnostics_storage_uri = optional(string)
    availability_zone            = optional(string)
    os_disk_type                 = optional(string, "Standard_LRS")
    os_disk_size_gb              = optional(number, 128)
    os_disk_name                 = optional(string)
    delete_os_disk_on_termination = optional(bool, true)
    computer_name                = optional(string)
    custom_data                  = optional(string)
    encryption_at_host_enabled   = optional(bool, false)
  }))
  default = {}
}

variable "nsg_rules" {
  type    = map(any)
  default = {}
}

variable "jump_ssh_source_cidr" {
  description = "Override SSH source for subnet-jump NSG when jump VM is Linux; e.g. VPN/bastion CIDR. Prod: do not use 0.0.0.0/0."
  type        = string
  default     = null
}

variable "jump_rdp_source_cidr" {
  description = "Override RDP source for subnet-jump NSG when jump VM is Windows; e.g. VPN/bastion CIDR. Prod: do not use 0.0.0.0/0."
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

variable "private_endpoints" {
  type = map(object({
    name              = string
    target_type       = string
    target_key        = string
    vnet_key          = string
    subnet_key        = string
    subresource_name  = string
  }))
  default = {}
}

variable "bastions" {
  description = "Azure Bastion Hosts"
  type = map(object({
    name               = string
    public_ip_name     = string
    vnet_key           = string
    subnet_key         = string
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

variable "sql_servers" {
  type = map(object({
    server_name     = string
    admin_username  = string
    admin_password  = string
    sql_version     = optional(string, "12.0")
    min_tls_version = optional(string, "1.2")
    firewall_rules = optional(map(object({
      start_ip_address = string
      end_ip_address   = string
    })), {})
    databases = optional(map(any), {})
  }))
  default = {}
}

variable "redis_caches" {
  type = map(object({
    name                 = string
    capacity             = optional(number, 0)
    family               = optional(string, "C")
    sku_name             = optional(string, "Basic")
    non_ssl_port_enabled = optional(bool, false)
    minimum_tls_version  = optional(string, "1.2")
  }))
  default = {}
}

variable "mysql_servers" {
  type = map(object({
    name                   = string
    administrator_login    = string
    administrator_password = string
    sku_name               = optional(string, "GP_Standard_D2ds_v4")
    mysql_version          = optional(string, "8.0.21")
    storage_size_gb        = optional(number, 20)
    backup_retention_days  = optional(number, 7)
    databases              = optional(map(any), {})
    firewall_rules         = optional(map(object({
      start_ip_address = string
      end_ip_address   = string
    })), {})
  }))
  default = {}
}

variable "app_services" {
  type = map(object({
    name                      = string
    plan_name                 = string
    os_type                   = optional(string, "Linux")
    sku_name                  = optional(string, "B1")
    app_settings              = optional(map(string), {})
    connection_strings        = optional(map(object({ type = string, value = string })), {})
    health_check_path         = optional(string)
    https_only                = optional(bool, true)
    identity_enabled          = optional(bool, true)
    always_on                 = optional(bool)
    client_certificate_enabled = optional(bool, false)
  }))
  default = {}
}

variable "function_apps" {
  type = map(object({
    name                   = string
    plan_name              = string
    sku_name               = optional(string, "Y1")
    storage_account_key    = optional(string)
    create_storage_account = optional(bool, true)
    app_settings           = optional(map(string), {})
  }))
  default = {}
}

variable "logic_apps" {
  type = map(object({
    name                 = string
    app_service_plan_key = string
    storage_account_key  = string
    app_settings         = optional(map(string), {})
  }))
  default = {}
}

variable "api_managements" {
  type = map(object({
    name            = string
    publisher_name  = string
    publisher_email = string
    sku_name        = optional(string, "Developer")
    vnet_key        = optional(string)
    subnet_key      = optional(string)
  }))
  default = {}
}

variable "aks_clusters" {
  type = map(object({
    name                              = string
    dns_prefix                        = string
    vnet_key                          = string
    subnet_key                        = string
    kubernetes_version                 = optional(string)
    default_node_pool_vm_size         = optional(string, "Standard_DS2_v2")
    default_node_pool_node_count      = optional(number, 1)
    default_node_pool_enable_auto_scaling = optional(bool, false)
    default_node_pool_min_count       = optional(number, 1)
    default_node_pool_max_count       = optional(number, 3)
    enable_azure_rbac                 = optional(bool, false)
    network_plugin                    = optional(string, "kubenet")
    user_node_pools                   = optional(map(object({
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

variable "registries" {
  type = map(object({
    name                          = string
    sku                           = optional(string, "Basic")
    admin_enabled                 = optional(bool, false)
    public_network_access_enabled = optional(bool, true)
  }))
  default = {}
}

variable "log_analytics_workspaces" {
  type = map(object({
    name             = string
    sku              = optional(string, "PerGB2018")
    retention_in_days = optional(number, 30)
  }))
  default = {}
}

variable "application_insights" {
  type = map(object({
    name             = string
    application_type = optional(string, "web")
    workspace_key    = optional(string)
  }))
  default = {}
}

variable "managed_identities" {
  type = map(object({
    name = string
  }))
  default = {}
}

variable "nat_gateways" {
  type = map(object({
    name                    = string
    public_ip_name          = string
    idle_timeout_in_minutes = optional(number, 10)
  }))
  default = {}
}

variable "recovery_services_vaults" {
  type = map(object({
    name                = string
    sku                 = optional(string, "Standard")
    soft_delete_enabled = optional(bool, true)
  }))
  default = {}
}

variable "private_dns_zones" {
  type = map(object({
    zone_name            = string
    vnet_keys            = list(string)
    registration_enabled = optional(bool, false)
  }))
  default = {}
}

variable "key_vault_secrets" {
  type = map(object({
    secret_name   = string
    secret_value  = string
    key_vault_key = string
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
  description = "Example secret value (use TF_VAR_ or sensitive variable; do not commit real secrets in tfvars)"
  type        = string
  default     = "example-secret-value"
}
