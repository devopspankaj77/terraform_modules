# Optional Security Controls via tfvars

These options are implemented in the modules and can be enabled by passing values in your environment `*.tfvars` files (dev.tfvars, prod.tfvars). They align with **RESOURCE_CONTROLS_SHEET.md** and **SECURITY_BASELINES.md**.

## Top-level (NSG – jump VM)

| Option                   | Type   | Default | Example |
|--------------------------|--------|---------|---------|
| `jump_rdp_source_cidr`  | string | `null`  | Set in tfvars or `TF_VAR_jump_rdp_source_cidr` (e.g. `"10.0.0.0/24"`) to restrict RDP to a single VPN/bastion CIDR. Ignored if the subnet-jump RDP rule uses `source_address_prefixes`. |
| `jump_ssh_source_cidr`  | string | `null`  | Set in tfvars or `TF_VAR_jump_ssh_source_cidr` to restrict SSH to jump (Linux) to VPN/bastion CIDR. |

**RDP from multiple corporate IPs:** In `nsg_rules.subnet-jump.allow_rdp` use `source_address_prefixes = ["1.2.3.4/32", "5.6.7.8/32", ...]` instead of `source_address_prefix` to allow only those IPs (vnet module supports both).

## Virtual Network (`vnets.<key>`)

| Option                         | Type          | Default | Example |
|--------------------------------|---------------|---------|---------|
| `subnets_allow_private_endpoint` | list(string) | `[]`    | `["subnet-data"]` or `["private-endpoints"]` — subnet names used for PaaS private endpoints; get `private_endpoint_network_policies = Disabled` (SECURITY_BASELINES 7.2). |

## Resource Group (`rg`)

| Option        | Type   | Default      | Example (prod)                    |
|---------------|--------|--------------|-----------------------------------|
| `create_lock` | bool   | `false`      | `create_lock = true`              |
| `lock_level`  | string | `"CanNotDelete"` | `lock_level = "CanNotDelete"`  |

## Storage Accounts (`storage_accounts.<key>`)

| Option                             | Type  | Default | Example |
|------------------------------------|-------|---------|---------|
| `blob_soft_delete_retention_days`  | number | `null` | `7` (dev), `30` (prod) |
| `container_soft_delete_retention_days` | number | `null` | `7` or `30` |
| `shared_key_access_disabled`       | bool  | `false` | Variable is passed; enable shared key restriction via Azure Portal/Policy if provider does not support it. |
| `network_rules`                    | object | `null` | `{ default_action = "Deny", bypass = ["AzureServices"], ip_rules = [], virtual_network_subnet_ids = [] }` |
| `create_delete_lock`               | bool  | `false` | `true` |

## Virtual Machines (`vms.<key>`)

| Option                         | Type   | Default | Example |
|--------------------------------|--------|---------|---------|
| `boot_diagnostics_enabled`     | bool   | `false` | `true` |
| `boot_diagnostics_storage_uri`| string | `null`  | Storage URI or `null` for managed |
| `availability_zone`            | string | `null`  | `"1"`, `"2"`, or `"3"` |
| `os_disk_type`                 | string | `"Standard_LRS"` | `"Premium_LRS"`, `"StandardSSD_LRS"` |
| `os_disk_size_gb`              | number | `128`   | `64`–`4096` |
| `os_disk_name`                 | string | `null`  | Custom OS disk name; null = `"${name}-osdisk"` |
| `delete_os_disk_on_termination`| bool   | `true`  | Documented only; use provider `features.virtual_machine.delete_os_disk_on_deletion` for actual behavior |
| `computer_name`                | string | `null`  | Hostname; null = VM name |
| `custom_data`                  | string | `null`  | Base64-encoded cloud-init (Linux) or script (Windows) |
| `encryption_at_host_enabled`   | bool   | `false` | `true` for sensitive workloads (security baseline) |

## Key Vaults (`keyvaults.<key>`)

| Option               | Type   | Default | Example |
|----------------------|--------|---------|---------|
| `network_acls`       | object | `null`  | `{ default_action = "Deny", bypass = "AzureServices", ip_rules = [], virtual_network_subnet_ids = [] }` |
| `create_delete_lock` | bool   | `false` | `true` |

## SQL Servers (`sql_servers.<key>`)

| Option                    | Type   | Default | Example |
|---------------------------|--------|---------|---------|
| `azuread_administrator`   | object | `null`  | `{ login = "sql-admins", object_id = "<guid>", tenant_id = null }` |
| `extended_auditing_policy` | object | `null` | Pass in tfvars; configure auditing via `azurerm_mssql_server_extended_auditing_policy` resource (e.g. in env) when needed. |
| In `databases.<db_key>`:  |        |         |         |
| `short_term_retention_days` | number | `null` | `7`–`35` |

## App Services (`app_services.<key>`)

| Option                     | Type | Default | Example |
|----------------------------|------|---------|---------|
| `https_only`               | bool | `true`  | `true` |
| `client_certificate_enabled` | bool | `false` | Set in tfvars; requires provider support for `site_config.client_certificate_mode` (mutual TLS). |
| `always_on`                | bool | `null` (SKU-based) | `true` |
| `identity_enabled`         | bool | `true`  | `true` |

## Recovery Services Vaults (`recovery_services_vaults.<key>`)

| Option               | Type | Default | Example |
|----------------------|------|---------|---------|
| `create_delete_lock` | bool | `false` | `true` |

---

**Usage:** Add or uncomment the desired keys in your `dev.tfvars` or `prod.tfvars`. Existing config remains valid; new keys use `try(each.value.<key>, default)` so omitting them leaves defaults unchanged.
