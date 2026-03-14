# Security Baselines for Terraform Project

This document defines the **complete security baseline** for all resources and modules in this Azure Terraform project. Use it to harden deployments, align with Azure security best practices, and satisfy audit or compliance requirements.

---

## Scope

| Area | Contents |
|------|----------|
| **Modules covered** | resource-group, vnet, vm, storage-account, keyvault, key-vault-secret, private-endpoint, private-dns-zone, bastion, sql, mysql, redis, app-service, function-app, logic-app, api-management, aks, registry, log-analytics, application-insights, managed-identity, nat-gateway, recovery-services |
| **Environments** | dev, and any uat/prod using the same module set |
| **References** | Azure Security Benchmark, Terraform security best practices, CIS benchmarks where applicable |

---

## Implementation in this repository

Modules and environment files have been aligned with the baseline so that options can be enabled via **tfvars** (dev.tfvars, prod.tfvars):

| Area | Implemented in | Enable via |
|------|----------------|------------|
| **RG** | resource-group module | `create_lock`, `lock_level` in `rg` |
| **VNet** | vnet module | `subnets_allow_private_endpoint` in `vnets.<key>` (PE subnets get network policies disabled) |
| **VM** | vm module | `boot_diagnostics_*`, `availability_zone`, `os_disk_*`, `computer_name`, `custom_data`, `encryption_at_host_enabled` |
| **Storage** | storage-account module | `blob/container_soft_delete_retention_days`, `network_rules`, `create_delete_lock` |
| **Key Vault** | keyvault module | `network_acls`, `create_delete_lock`; RBAC, soft delete, purge protection, `public_network_access_enabled = false` |
| **SQL** | sql module | `azuread_administrator`; in databases: `short_term_retention_days`; `minimum_tls_version` |
| **App Service** | app-service module | `https_only`, `identity_enabled`, `always_on`; FTPS disabled |
| **Recovery Services** | recovery-services module | `create_delete_lock`, `soft_delete_enabled` |
| **NSG (jump)** | dev/prod main.tf | `jump_rdp_source_cidr`, `jump_ssh_source_cidr` (TF_VAR or tfvars) |

See **OPTIONAL_SECURITY_TFVARS.md** and the SECURITY OPTIONS REFERENCE block at the end of dev.tfvars / prod.tfvars for all keys.

---

## 1. Terraform State Security

| Baseline | Status | Action |
|----------|--------|--------|
| Use remote backend (e.g. `azurerm`) for all environments | ⚠️ Partial | Enable and configure `backend "azurerm"` in each environment's `backend.tf`. |
| Backend storage: encryption at rest | ✅ | Azure Storage encrypts at rest by default. |
| Restrict state access via RBAC + private endpoint | 🔴 | Use a dedicated storage account for state; enable firewall + private endpoint; grant access only to CI/service principal. |
| State file key per environment | ✅ | Use distinct keys (e.g. `dev.terraform.tfstate`, `prod.terraform.tfstate`). |
| Prefer Azure AD auth for backend | — | Set `use_azuread = true` in backend block when supported. |

**Example backend configuration:**

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-<env>"
    storage_account_name = "tfstate<unique>"
    container_name       = "tfstate"
    key                  = "<env>.terraform.tfstate"
    use_azuread          = true
  }
}
```

---

## 2. Secrets and Sensitive Data

| Baseline | Status | Action |
|----------|--------|--------|
| No passwords, keys, or connection strings in committed `.tf` / `.tfvars` | ⚠️ | Use `TF_VAR_*` or Key Vault for SQL/MySQL/VM/admin passwords and app secrets. |
| Sensitive variables marked `sensitive = true` | ✅ | Used for `admin_password`, SQL/MySQL passwords, Key Vault secrets. |
| No secrets in committed tfvars for production | 🔴 | Use `*.tfvars.example` and inject via CI or exclude secret-containing tfvars from Git. |
| Key Vault for app secrets (connection strings, API keys) | ✅ | `key_vault_secrets` module; reference secrets from apps via Key Vault references. |

**Injection methods:**

- **Preferred:** Azure Key Vault + `data "azurerm_key_vault_secret"` or CI/CD secret variables (`TF_VAR_*`).
- **Avoid:** Plain-text passwords in committed `prod.tfvars` or `dev.tfvars`.

**Outputs:**

| Baseline | Status |
|----------|--------|
| Sensitive outputs use `sensitive = true` | ✅ |
| Minimize sensitive outputs; prefer Key Vault/CI for secrets | ✅ |

---

## 3. Provider and Identity

| Baseline | Status | Action |
|----------|--------|--------|
| No hardcoded subscription ID in provider | ✅ | Use `ARM_SUBSCRIPTION_ID` or Azure CLI. |
| Provider versions pinned | ✅ | `required_providers` with version constraints; `.terraform.lock.hcl` committed. |
| Use workload identity / service principal in CI | — | Prefer OIDC or client credentials; avoid long-lived client secrets in code. |

---

## 4. Network Security

### 4.1 NSG and Firewall Rules

| Baseline | Status | Action |
|----------|--------|--------|
| No `0.0.0.0/0` or `*` for SSH (22) / RDP (3389) in production | ✅ | Set `TF_VAR_jump_rdp_source_cidr` (Windows) or `TF_VAR_jump_ssh_source_cidr` (Linux) to VPN/bastion CIDR. |
| Deny-by-default; explicit allow rules only | ✅ | NSG rules are allow-only; avoid broad "allow all" in prod. |
| Restrict data-plane ports (SQL 1433, Redis 6379, etc.) to app subnets | ✅ | Example: SQL from `10.10.1.0/24`; replicate for all data stores. |

### 4.2 Private Endpoints and Public Access

| Baseline | Status | Action |
|----------|--------|--------|
| Private endpoints for Key Vault, Storage, SQL, MySQL, Redis, ACR, App Service | ✅ | Supported in dev via `private_endpoints` map and PE-backed DNS zones. |
| Disable public network access where supported | ✅ | Key Vault and Storage modules set `public_network_access_enabled = false`. |
| Private DNS zones for private endpoints | ✅ | Zones created in main.tf when corresponding PE type exists; VNet links applied. |

### 4.3 Public IPs (VMs, Bastion, NAT)

| Baseline | Status | Action |
|----------|--------|--------|
| No public IP on VMs unless required (e.g. jump box) | ✅ | VM module: `create_public_ip` (default false). |
| Restrict SSH/RDP to jump to VPN/bastion CIDR in prod | ✅ | Use `TF_VAR_jump_rdp_source_cidr` / `TF_VAR_jump_ssh_source_cidr`. |
| Public IPs: Standard SKU, static allocation | ✅ | VM, Bastion, NAT use `sku = "Standard"`, `allocation_method = "Static"`. |

---

## 5. Identity and Access (RBAC)

### 5.1 Key Vault

| Baseline | Status | Action |
|----------|--------|--------|
| RBAC for Key Vault (not access policies) | ✅ | `rbac_authorization_enabled = true` in module. |
| Soft delete and purge protection | ✅ | Configurable; set `soft_delete_retention_days` (e.g. 90), `purge_protection_enabled = true` in prod. |

### 5.2 Virtual Machines

| Baseline | Status | Action |
|----------|--------|--------|
| Prefer Azure AD login over local accounts | ✅ | AAD login extension (Linux/Windows); "Virtual Machine Administrator Login" role. |
| Linux: disable password auth; use SSH keys | ✅ | `disable_password_authentication = true` in VM module. |
| System-assigned managed identity on VMs | ✅ | Enabled in VM module. |

### 5.3 AKS

| Baseline | Status | Action |
|----------|--------|--------|
| Azure AD integration and Azure RBAC | ✅ | Module supports `enable_azure_rbac` and `admin_group_object_ids`; set in prod. |
| Prefer Azure RBAC over local kube-admin | — | Use `azure_rbac_enabled = true`; avoid exporting raw kubeconfig with admin certs. |

---

## 6. Data Protection and Encryption

| Baseline | Status | Action |
|----------|--------|--------|
| Storage: HTTPS only, minimum TLS 1.2 | ✅ | `https_traffic_only_enabled = true`, `min_tls_version = "TLS1_2"` in storage module. |
| SQL Server: minimum TLS 1.2 | ✅ | `minimum_tls_version` in SQL module (default 1.2). |
| Redis: non-SSL port disabled, minimum TLS 1.2 | ✅ | `non_ssl_port_enabled = false`, `minimum_tls_version = "1.2"` in Redis. |
| Key Vault: TLS 1.2+ (Azure default) | ✅ | No override; Azure enforces. |
| Blob versioning for critical storage | ✅ | `enable_blob_versioning` in storage module. |

---

## 7. Per-Module Security Baseline

### 7.1 resource-group

| Control | Implemented in module | Recommended in tfvars |
|---------|------------------------|------------------------|
| Tagging | Via `common_tags` from root | Set company-mandatory tags (Created By, Environment, etc.). |
| Location | Required variable | Use approved regions only. |

### 7.2 vnet (Virtual Network)

| Control | Implemented in module | Recommended in tfvars |
|---------|------------------------|------------------------|
| NSG per subnet or shared | ✅ `create_nsg`, `nsg_per_subnet` | Use per-subnet NSGs for isolation. |
| NSG rules | ✅ `nsg_rules` map | Restrict source/dest; no 0.0.0.0/0 for management ports in prod. |
| Private endpoint subnet | ✅ Optional `create_private_endpoint_subnet` | Use for PaaS private endpoints; disable network policies on PE subnet. |
| No default NSG "allow all" | ✅ | Define explicit allow rules only. |

### 7.3 vm (Virtual Machine)

| Control | Implemented in module | Recommended in tfvars |
|---------|------------------------|------------------------|
| Linux: SSH only, no password | ✅ `disable_password_authentication = true` | Use strong SSH key; rotate periodically. |
| Windows: strong password policy | N/A (Azure enforces) | Use complex password; prefer Azure AD login. |
| Azure AD login (Linux/Windows) | ✅ AAD extension | Assign "Virtual Machine Administrator Login" to users/groups. |
| System-assigned managed identity | ✅ | Use for Key Vault / storage access from VM. |
| Public IP only when needed | ✅ `create_public_ip` | Only jump box; restrict RDP/SSH source in prod. |
| Public IP: Standard SKU, static | ✅ | — |

### 7.4 storage-account

| Control | Implemented in module | Recommended in tfvars |
|---------|------------------------|------------------------|
| Public network access disabled | ✅ `public_network_access_enabled = false` | — |
| HTTPS only | ✅ `https_traffic_only_enabled = true` | — |
| Minimum TLS 1.2 | ✅ `min_tls_version = "TLS1_2"` | — |
| Blob versioning | ✅ Optional `enable_blob_versioning` | Enable for critical data. |
| Container access | ✅ `containers[*].access_type` | Use `private` for sensitive containers. |
| Private endpoint | Via root `private_endpoints` | Use PE + private DNS for all storage in prod. |

### 7.5 keyvault

| Control | Implemented in module | Recommended in tfvars |
|---------|------------------------|------------------------|
| Public network access disabled | ✅ `public_network_access_enabled = false` | — |
| RBAC only | ✅ `rbac_authorization_enabled` | Set `true`; do not use access policies. |
| Soft delete | ✅ `soft_delete_retention_days` | Use 90 in prod. |
| Purge protection | ✅ `purge_protection_enabled` | Set `true` in prod. |
| Private endpoint | Via root `private_endpoints` | Use PE + private DNS. |

### 7.6 key-vault-secret

| Control | Implemented in module | Recommended in tfvars |
|---------|------------------------|------------------------|
| Secret value from variable | ✅ `secret_value` (sensitive) | Never commit; use `TF_VAR_*` or Key Vault reference. |
| RBAC on Key Vault | Handled at Key Vault | Grant "Key Vault Secrets Officer" (or minimal) to identity creating secrets. |
| Content type | Optional `content_type` | Use for clarity (e.g. `text/plain`). |

### 7.7 private-endpoint

| Control | Implemented in module | Recommended in tfvars |
|---------|------------------------|------------------------|
| Private DNS zone group | ✅ When `private_dns_zone_id` provided | Always pass zone ID for automatic DNS. |
| Subnet: private endpoint policies | N/A | Use subnet with `private_endpoint_network_policies = "Disabled"`. |

### 7.8 private-dns-zone

| Control | Implemented in module | Recommended in tfvars |
|---------|------------------------|------------------------|
| VNet links | In root/main.tf | Link only to intended VNets. |
| No public resolution | N/A | Private zones are not public. |

### 7.9 bastion

| Control | Implemented in module | Recommended in tfvars |
|---------|------------------------|------------------------|
| Standard SKU, static public IP | ✅ | — |
| Copy/paste / file copy / tunneling | ✅ Configurable | Disable file copy/tunneling if not required. |

### 7.10 sql (Azure SQL Database)

| Control | Implemented in module | Recommended in tfvars |
|---------|------------------------|------------------------|
| Minimum TLS 1.2 | ✅ `minimum_tls_version` | Use 1.2. |
| Firewall rules | ✅ `firewall_rules` | Restrict to app subnet/VNet; avoid 0.0.0.0/0. |
| Admin password | Variable (sensitive) | Use Key Vault or `TF_VAR_*`; never commit. |
| Private endpoint | Via root `private_endpoints` | Use PE + private DNS in prod. |

### 7.11 mysql (Azure Database for MySQL Flexible)

| Control | Implemented in module | Recommended in tfvars |
|---------|------------------------|------------------------|
| Administrator password | Variable (sensitive) | Use Key Vault or `TF_VAR_*`. |
| Firewall rules | ✅ `firewall_rules` | Restrict to app subnet; use empty map when using PE only. |
| Backup / HA | ✅ `backup_retention_days`, `geo_redundant_backup_enabled` | Set per policy. |
| Private endpoint | Via root `private_endpoints` | Use PE + private DNS in prod. |

### 7.12 redis (Azure Cache for Redis)

| Control | Implemented in module | Recommended in tfvars |
|---------|------------------------|------------------------|
| Non-SSL port disabled | ✅ `non_ssl_port_enabled = false` | — |
| Minimum TLS 1.2 | ✅ `minimum_tls_version = "1.2"` | — |
| Private endpoint | Via root `private_endpoints` | Use PE + private DNS in prod. |

### 7.13 app-service (App Service / Web App)

| Control | Implemented in module | Recommended in tfvars |
|---------|------------------------|------------------------|
| FTPS disabled | ✅ `ftps_state = "Disabled"` | — |
| Connection strings / app settings | Via variables | Use Key Vault references for secrets. |
| Private endpoint | Via root `private_endpoints` | Use PE for production. |

### 7.14 function-app

| Control | Implemented in module | Recommended in tfvars |
|---------|------------------------|------------------------|
| FTPS disabled | ✅ `ftps_state = "Disabled"` | — |
| Storage key for runtime | Variable | Prefer Key Vault reference for storage key in prod. |

### 7.15 logic-app

| Control | Implemented in module | Recommended in tfvars |
|---------|------------------------|------------------------|
| Storage (state) | Uses storage from root | Prefer Key Vault reference for storage key. |

### 7.16 api-management

| Control | Implemented in module | Recommended in tfvars |
|---------|------------------------|------------------------|
| System-assigned identity | ✅ | Use for Key Vault or backend auth. |
| VNet integration | ✅ Optional `subnet_id` | Use for private exposure. |
| HTTP/2 | Optional `disable_http2` | Disable if not required. |

### 7.17 aks (Azure Kubernetes Service)

| Control | Implemented in module | Recommended in tfvars |
|---------|------------------------|------------------------|
| Azure AD + Azure RBAC | ✅ `enable_azure_rbac`, `admin_group_object_ids` | Enable in prod; set admin group. |
| Network policy | ✅ `network_policy` (e.g. azure) | Enable for micro-segmentation. |
| Standard load balancer | ✅ `load_balancer_sku = "standard"` | — |
| Private cluster | Optional (not in module) | Consider for prod. |

### 7.18 registry (ACR)

| Control | Implemented in module | Recommended in tfvars |
|---------|------------------------|------------------------|
| Admin user disabled | ✅ `admin_enabled` (default false) | Keep `false` in prod; use managed identity or AAD. |
| Public network access | ✅ `public_network_access_enabled` (default true) | Set `false` in prod when using private endpoint. |
| Private endpoint | Via root `private_endpoints` | Use PE + private DNS in prod. |

### 7.19 log-analytics

| Control | Implemented in module | Recommended in tfvars |
|---------|------------------------|------------------------|
| Retention | ✅ Configurable | Set per compliance (e.g. 90–365 days). |
| No sensitive data in log content | N/A | Ensure diagnostic settings do not log secrets. |

### 7.20 application-insights

| Control | Implemented in module | Recommended in tfvars |
|---------|------------------------|------------------------|
| Link to Log Analytics | Via `workspace_key` | Use for unified retention and query. |
| No secrets in custom dimensions | N/A | Avoid logging connection strings or keys. |

### 7.21 managed-identity (User-Assigned)

| Control | Implemented in module | Recommended in tfvars |
|---------|------------------------|------------------------|
| Least privilege | N/A | Assign only required roles (e.g. Key Vault Secrets User, Storage Blob Contributor). |

### 7.22 nat-gateway

| Control | Implemented in module | Recommended in tfvars |
|---------|------------------------|------------------------|
| Stable outbound IP | ✅ | Use for allow-listing; associate to subnets that need egress control. |

### 7.23 recovery-services (Recovery Services Vault)

| Control | Implemented in module | Recommended in tfvars |
|---------|------------------------|------------------------|
| Soft delete | ✅ `soft_delete_enabled` | Enable for backup protection. |
| RBAC for backup operators | N/A | Assign Backup Contributor etc. via RBAC. |

---

## 8. Supply Chain and Code Quality

| Baseline | Status | Action |
|----------|--------|--------|
| Terraform version constraint | ✅ | e.g. `required_version = ">= 1.0"`. |
| Lock file committed | ✅ | `.terraform.lock.hcl` in repo. |
| No inline scripts or untrusted external data | ✅ | No risky `external` or inline scripts. |
| `.gitignore` excludes state, secrets, `.terraform/` | ✅ | Add `*.tfvars` for env-specific/secret files if needed. |
| No unattended `terraform apply -auto-approve` in prod | ⚠️ | Use manual or gated pipeline apply; plan in PR. |

---

## 9. Compliance and Scanning

| Action | Recommendation |
|--------|----------------|
| Plan in CI | Run `terraform plan` for every PR; block merge on plan failure or destructive changes. |
| Terraform scanning | Use **tfsec** or **checkov** for Terraform security scanning. |
| Azure Policy | Enable Defender and Policy (allowed locations, require tags, encryption) on subscriptions. |
| Audit logging | Ensure diagnostic settings send logs to Log Analytics; retain per policy. |

---

## 10. Quick Reference Checklist

| Priority | Item |
|----------|------|
| 1 | Restrict RDP/SSH to jump VM in prod via `TF_VAR_jump_rdp_source_cidr` / `TF_VAR_jump_ssh_source_cidr`. |
| 2 | No secrets in committed tfvars; use `TF_VAR_*` or Key Vault. |
| 3 | Enable remote backend for state; restrict state storage with RBAC + private endpoint. |
| 4 | Key Vault: RBAC only, soft delete 90d, purge protection, private endpoint. |
| 5 | ACR: `admin_enabled = false`, `public_network_access_enabled = false` when using PE. |
| 6 | AKS: Enable Azure RBAC and network policy in prod. |
| 7 | Never use unattended `terraform apply -auto-approve` in production. |

---

## 11. Dev Environment Summary

| Area | Status | Notes |
|------|--------|--------|
| Provider | ✅ | No hardcoded subscription; use `ARM_SUBSCRIPTION_ID`. |
| Secrets | ⚠️ | Use `TF_VAR_*` or Key Vault for SQL/MySQL/VM passwords. |
| Key Vault | ✅ | RBAC, purge protection, no public access. |
| Storage | ✅ | TLS 1.2, HTTPS only, versioning, no public access. |
| Private endpoints | ✅ | Storage, Key Vault, and optional SQL/MySQL/Redis/ACR/App Service. |
| NSG | ✅ | Restrict jump RDP/SSH in prod via env vars. |
| VM | ✅ | Linux: SSH + AAD; Windows: RDP + AAD; VM Admin Login role. |
| Backend | ⚠️ | Enable remote backend for shared/CI use. |
| ACR | ⚠️ | Set `admin_enabled = false`, `public_network_access_enabled = false` when using PE. |

---

## 12. Implementation Steps: Enterprise Baseline for Dev Environment

The following steps close the gaps where the dev environment is **lagging** (⚠️ or 🔴) against the enterprise baseline. Execute in order where dependencies apply.

### 12.1 Terraform state: remote backend and locked-down storage

**Gap:** Remote backend not enabled; state storage not restricted with RBAC + private endpoint.

| Step | Action | Details |
|------|--------|--------|
| 1 | Create a dedicated resource group for Terraform state (one-time, can be manual or separate TF). | e.g. `rg-tfstate-dev` in the same subscription. |
| 2 | Create a storage account for state. | Name globally unique (e.g. `tfstateicr002deveus`). Enable **HTTPS only**, **min TLS 1.2**, **no public blob access**. Do **not** allow public network access if you will add a private endpoint. |
| 3 | Create a container in that storage account. | e.g. `tfstate`. |
| 4 | In `environments/dev/backend.tf` (or create it), add the backend block. | Set `resource_group_name`, `storage_account_name`, `container_name`, `key = "dev.terraform.tfstate"`. Prefer `use_azuread = true` if your provider supports it. |
| 5 | Run `terraform init -reconfigure` from `environments/dev`. | This migrates state to the remote backend (or initializes with empty state). |
| 6 | Restrict access to the state storage account. | Remove broad "Storage Blob Contributor" from subscription; grant **Storage Blob Data Contributor** (or equivalent) only to the identity that runs Terraform (e.g. CI service principal, or your user for local dev). Use RBAC; avoid access keys for CI. |
| 7 | (Optional, higher security) Add private endpoint for state storage. | Create a subnet for TF state (or reuse a private subnet), create private endpoint for blob on the state storage account, and private DNS zone for `privatelink.blob.core.windows.net`. Run Terraform from a network that can reach the private endpoint (e.g. Azure DevOps agent in VNet, or VPN). |

**Verification:** Run `terraform plan -var-file=dev.tfvars` from `environments/dev`; state should be read from/written to the remote backend.

---

### 12.2 Secrets: remove from committed tfvars and use TF_VAR / Key Vault

**Gap:** Passwords or other secrets in committed `dev.tfvars` (e.g. SQL, MySQL, jump VM admin).

| Step | Action | Details |
|------|--------|--------|
| 1 | Identify all sensitive variables used by dev. | e.g. `admin_password` (VM jump), `sql_servers.*.admin_password`, `mysql_servers.*.administrator_password`, `key_vault_secrets.*.secret_value`. |
| 2 | Remove or redact secrets from `dev.tfvars`. | Replace literal passwords with placeholders or remove the keys; rely on defaults or env. For VM jump, ensure `admin_password` is not set in tfvars (or set to null) so it is supplied via env. |
| 3 | Set secrets via environment variables before plan/apply. | PowerShell: `$env:TF_VAR_jump_admin_password = 'YourPassword'`; Bash: `export TF_VAR_jump_admin_password='YourPassword'`. For SQL: `TF_VAR_sql_admin_password` (if you add a variable), or use a `terraform.tfvars` that is gitignored. |
| 4 | (Preferred for production) Store secrets in Key Vault. | Create secrets in Key Vault (manually or via Terraform with a one-time bootstrap). In Terraform, use `data "azurerm_key_vault_secret"` to read them and pass to modules (e.g. SQL admin password). Ensure the identity running Terraform has **Key Vault Secrets User** (or get) on that Key Vault. |
| 5 | Optionally add `dev.tfvars.example`. | Copy `dev.tfvars` to `dev.tfvars.example`; replace all secret values with placeholders (e.g. `"<set-via-TF_VAR_jump_admin_password>"`). Add `dev.tfvars` to `.gitignore` if it will ever hold real secrets. |

**Verification:** Run `terraform plan -var-file=dev.tfvars` with secrets set only via `TF_VAR_*` (and no secrets in `dev.tfvars`); plan should succeed.

---

### 12.3 No secrets in committed tfvars (repository and CI)

**Gap:** Risk of committing env-specific or secret-containing tfvars.

| Step | Action | Details |
|------|--------|--------|
| 1 | Decide which tfvars are “safe” to commit. | e.g. `dev.tfvars.example` with placeholders is safe; `dev.tfvars` with real secrets is not. |
| 2 | Update `.gitignore` if needed. | Add `dev.tfvars` (or `*.tfvars`) if that file will hold secrets; keep `dev.tfvars.example` tracked. |
| 3 | In CI, inject secrets as pipeline variables (secret/masked). | Set `TF_VAR_jump_admin_password`, `TF_VAR_sql_admin_password`, etc. as secret variables; do not store them in repo or in plain pipeline config. |
| 4 | Use a separate tfvars file for CI if required. | e.g. `dev.auto.tfvars` generated or provided by CI from secrets; ensure it is not committed. |

**Verification:** No file under version control contains real passwords or connection strings; CI runs succeed with secrets from variable group or Key Vault.

---

### 12.4 Restrict jump VM RDP/SSH in dev (align with prod pattern)

**Gap:** Dev may use `*` for RDP/SSH source; baseline requires restriction in prod; dev should mirror the mechanism.

| Step | Action | Details |
|------|--------|--------|
| 1 | For local dev, decide allowed source. | e.g. your corporate VPN CIDR or a single IP. |
| 2 | Set environment variable before plan/apply. | PowerShell: `$env:TF_VAR_jump_rdp_source_cidr = "YOUR_IP/32"` (Windows jump) or `$env:TF_VAR_jump_ssh_source_cidr = "YOUR_IP/32"` (Linux jump). |
| 3 | Ensure `main.tf` uses this for NSG. | The dev root module should use `coalesce(var.jump_rdp_source_cidr, nsg_rules value)` (or equivalent) so the env var overrides the tfvars value. If not, add this logic so prod and dev can restrict source without editing tfvars. |

**Verification:** After apply, NSG rule for subnet-jump shows the restricted source (e.g. your IP/32) when the env var is set.

---

### 12.5 Key Vault: soft delete and purge protection (dev alignment with baseline)

**Gap:** Baseline recommends 90-day soft delete and purge protection; dev may use shorter retention.

| Step | Action | Details |
|------|--------|--------|
| 1 | In `dev.tfvars` (or the tfvars you use for dev), set Key Vault options. | `soft_delete_retention_days = 90`, `purge_protection_enabled = true`. Note: purge protection cannot be disabled once enabled. |
| 2 | If Key Vault already exists with different settings. | Increase soft delete retention via Terraform (Azure allows increase). Enable purge protection only if you are sure (irreversible). Apply in a maintenance window. |

**Verification:** Key Vault in portal shows desired soft delete retention and purge protection.

---

### 12.6 ACR: disable admin user and public network when using private endpoint

**Gap:** ACR may have `admin_enabled = true` or `public_network_access_enabled = true` while using private endpoint.

| Step | Action | Details |
|------|--------|--------|
| 1 | In `dev.tfvars`, set ACR for enterprise baseline. | Under `registries.main` (or your ACR key): `admin_enabled = false`, `public_network_access_enabled = false`. |
| 2 | Ensure private endpoint and private DNS for ACR exist. | In `private_endpoints`, include an entry with `target_type = "acr"` and correct `subresource_name = "registry"`; ensure private DNS zone for ACR is created and linked (handled by root module when `acr_pe` exists). |
| 3 | Use managed identity or Azure AD for ACR pull/push. | Grant the identity (e.g. AKS, pipeline, dev VM) **AcrPull** or **AcrPush** on the ACR; do not re-enable admin user. |

**Verification:** ACR has no admin user, public network access disabled; workloads pull images via private endpoint using managed identity.

---

### 12.7 Pipeline: no unattended apply in production; plan in PR

**Gap:** Unattended `terraform apply -auto-approve` in production.

| Step | Action | Details |
|------|--------|--------|
| 1 | For **dev** only, allow optional auto-approve in pipeline. | Use a variable or branch condition so that only dev (or feature branches) can run apply with `-auto-approve`; never on main/prod. |
| 2 | For **prod** (and preferably uat), require manual approval. | Add an approval gate before the apply step; use `terraform plan` only in PR and persist plan artifact; apply in a separate, gated job that uses the same plan. |
| 3 | Run plan on every PR. | Run `terraform plan -var-file=dev.tfvars` (or appropriate tfvars) in CI; fail the build if plan fails or if the plan shows unexpected destructive changes (optional: use `terraform show -json` and policy to block certain changes). |

**Verification:** Prod/uat pipelines have an approval step before apply; no pipeline runs `apply -auto-approve` on production.

---

### 12.8 Optional: Terraform security scanning in CI

**Gap:** No automated Terraform security scan.

| Step | Action | Details |
|------|--------|--------|
| 1 | Add a CI step to run tfsec or checkov. | e.g. `tfsec .` or `checkov -d . --framework terraform`. Run on PR; optionally fail on high/critical findings. |
| 2 | Fix or suppress findings. | Address true positives; use tfsec/checkov ignore comments for accepted risks with a short justification. |

**Verification:** Every PR runs the scanner; baseline violations are documented or fixed.

---

### 12.9 Summary checklist (dev environment)

| # | Gap | Step reference | Done |
|---|-----|----------------|------|
| 1 | Remote backend + state storage locked down | 12.1 | ☐ |
| 2 | No secrets in committed tfvars; use TF_VAR / Key Vault | 12.2 | ☐ |
| 3 | .gitignore and CI secret handling | 12.3 | ☐ |
| 4 | Restrict RDP/SSH source for jump VM | 12.4 | ☐ |
| 5 | Key Vault soft delete 90d + purge protection | 12.5 | ☐ |
| 6 | ACR admin disabled + no public access when using PE | 12.6 | ☐ |
| 7 | No unattended apply in prod; plan in PR | 12.7 | ☐ |
| 8 | (Optional) Terraform security scanning in CI | 12.8 | ☐ |

---

*This baseline applies to all modules and resources in this repository. Revisit when adding new modules or environments.*
