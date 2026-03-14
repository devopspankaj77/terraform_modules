# Production Environment — Same Structure as Dev

This folder uses the **same variable and module structure as dev**: `rg = {}`, `vnets = { main = {} }`, `vms = {}`, `storage_accounts = {}`, etc., with `for_each` modules. Only the values in `prod.tfvars` differ (naming, security defaults). Aligned with **SECURITY_BASELINES.md** and **RESOURCE_CONTROLS_SHEET.md**.

## Prerequisites

- Terraform >= 1.0
- Azure CLI logged in (or service principal via `ARM_*` / `TF_VAR_*`)
- **Sensitive values must be set via environment variables** — do not commit secrets in `prod.tfvars`

## Required environment variables (secrets)

Set before `terraform plan` or `apply`:

```powershell
# PowerShell
$env:TF_VAR_sql_admin_password    = "<secure-password>"
$env:TF_VAR_mysql_admin_password  = "<secure-password>"
# If using Windows jump VM:
$env:TF_VAR_jump_admin_password   = "<secure-password>"
# If using Linux VM: SSH key and/or password (use TF_VAR_ssh_public_key and/or set admin_password in vms in tfvars)
$env:TF_VAR_ssh_public_key       = "<your-public-key>"
```

```bash
# Bash
export TF_VAR_sql_admin_password="<secure-password>"
export TF_VAR_mysql_admin_password="<secure-password>"
export TF_VAR_jump_admin_password="<secure-password>"
export TF_VAR_ssh_public_key="<your-public-key>"
```

## Backend configuration (local state initially)

**Initial setup:** The prod backend is commented out in `backend.tf`, so Terraform uses **local state** (`terraform.tfstate` in this directory). Do not commit `terraform.tfstate` or `terraform.tfstate.backup` to Git; add them to `.gitignore`.

**When moving to remote state** (per SECURITY_BASELINES.md): Uncomment the `terraform { backend "azurerm" { ... } }` block in `backend.tf`, then run:

```bash
terraform init -reconfigure \
  -backend-config="resource_group_name=rg-tfstate-prod" \
  -backend-config="storage_account_name=<unique-name>" \
  -backend-config="container_name=tfstate"
```

Do not commit backend access keys; use Azure AD auth when possible.

## Commands

```bash
terraform init -reconfigure
terraform plan -var-file=prod.tfvars
# Manual review; do not use -auto-approve in production (per security baseline)
terraform apply -var-file=prod.tfvars
```

## Security baseline summary

| Area | Implementation |
|------|----------------|
| **Secrets** | No passwords in tfvars; use `TF_VAR_*` or Key Vault |
| **Key Vault** | RBAC only, 90d soft delete, purge protection |
| **Storage** | GZRS/ZRS, TLS 1.2+, blob versioning, no public access |
| **SQL/MySQL** | TLS 1.2, firewall restricted, password via env |
| **VM** | No public IP (use Bastion); restrict RDP/SSH source in NSG; optional: os_disk_type, os_disk_size_gb, computer_name, custom_data, encryption_at_host_enabled (see OPTIONAL_SECURITY_TFVARS.md) |
| **AKS** | Azure RBAC, network policy, multi-node |
| **ACR** | Admin disabled, no public access when using PE |
| **Redis** | Non-SSL disabled, TLS 1.2 |
| **Backend** | Local state initially (see backend.tf); migrate to remote azurerm; separate key per env |

See **SECURITY_BASELINES.md** and **RESOURCE_CONTROLS_SHEET.md** in the repo root for full controls.

## Prod security baseline checklist (per RESOURCE_CONTROLS_SHEET)

| Control | Status in prod |
|--------|-----------------|
| Secrets via TF_VAR_* only (no passwords in tfvars) | ✅ Documented; set TF_VAR_sql_admin_password, TF_VAR_mysql_admin_password |
| Key Vault: RBAC only, 90d soft delete, purge protection | ✅ variables + tfvars |
| Key Vault: private endpoint + private DNS | ✅ main.tf (when PE subnet enabled) |
| Storage: GZRS/ZRS, TLS 1.2+, versioning, no public access | ✅ module + tfvars |
| Storage: private endpoint | ✅ main.tf (when PE subnet enabled) |
| SQL: TLS 1.2, firewall restricted, password via env | ✅ |
| MySQL: firewall restricted, password via env | ✅ |
| VM: no public IP (use Bastion) | ✅ vm_create_public_ip = false |
| NSG: no 0.0.0.0/0 for RDP/SSH; define nsg_rules with restricted source | ⚠️ Populate nsg_rules; use jump_rdp_source_cidr / jump_ssh_source_cidr |
| AKS: Azure RBAC, network policy (azure), network_plugin azure | ✅ Set in aks_clusters map when used |
| ACR: admin disabled, no public access when using PE | ✅ Set in registries map when used |
| Redis: non-SSL disabled, TLS 1.2 | ✅ |
| Backend: local state initially; then remote; separate key per env | ✅ backend.tf commented for local; uncomment for remote (key = prod.terraform.tfstate) |
| No terraform apply -auto-approve in prod | Process: use manual or gated apply |
