# Dev Environment — Full Project Setup

This environment creates for a **new project** in one apply:

| Resource        | Purpose                          |
|----------------|-----------------------------------|
| Resource Group | Container for all resources       |
| VNet           | Virtual network (e.g. 10.0.0.0/16)|
| Subnets        | e.g. subnet-app, subnet-data, subnet-jump |
| Linux VM (app) | Ubuntu 22.04 in subnet-app        |
| **Jump VM**    | **Windows Server 2022** in subnet-jump (RDP) |
| Storage Account| With blob container `data`        |
| Azure Key Vault| Standard SKU                      |

## Deployment verification (dev and prod)

- **Validate:** `terraform validate` passes in both `environments/dev` and `environments/prod`.
- **Plan:** `terraform plan -var-file=dev.tfvars` (dev) and `terraform plan -var-file=prod.tfvars` (prod) run successfully. Resources are created only when their maps are non-empty in tfvars (e.g. set `vms = { ... }` to deploy VMs when required).

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.0
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed and logged in:

  ```bash
  az login
  az account set -s "<subscription-id>"
  ```

## Full deployment checklist (all resources)

With the current `dev.tfvars`, all resource blocks are uncommented. For a **full apply** to succeed:

| Requirement | Action |
|-------------|--------|
| **Jump VM (Windows)** | Set `TF_VAR_jump_admin_password` before **plan or apply** (required; otherwise you get \"admin_password is required when os_type is windows\"). |
| **Linux app VM** | At least one of: SSH key (`vms.vm-app.ssh_public_key` or `TF_VAR_ssh_public_key`) or `admin_password` (Linux supports SSH-only, password-only, or both). |
| **Key Vault / APIM / Redis / ACR / Storage** | Names must be globally unique; change suffix in tfvars if you get "already exists" or "name unavailable". |
| **SQL / MySQL** | If your subscription has provisioning restricted in `eastus`, set `sql_servers = {}` and `mysql_servers = {}` and remove `sql_pe` and `mysql_pe` from `private_endpoints`. |
| **App Service / Function App** | If quota (Basic VMs / Dynamic VMs) is 0, set `app_services = {}`, `function_apps = {}`, `logic_apps = {}` and remove `app_pe` from `private_endpoints`. |
| **AKS** | Default node pool uses `Standard_F4s_v2`; if your region has different allowed SKUs, set `default_node_pool_vm_size` in `aks_clusters.main`. |

**Dependency order (handled by Terraform):** RG → VNet/subnets → VMs, Storage, Key Vault, etc. → Private Endpoints (depend on their targets). Logic Apps depend on App Service Plan and Storage; Function Apps depend on Storage; Key Vault Secrets depend on Key Vault and the Secrets Officer role assignment (enforced via `depends_on`).

## Usage

1. **Jump VM (Windows):** Use either (a) `admin_password` in the `vm-jump` block in `dev.tfvars`, or (b) set `TF_VAR_jump_admin_password` before plan/apply. If neither is set, a default placeholder is used so plan/apply can run—**change it** in tfvars or via the env var for a secure password.

   - **PowerShell:**  
     `$env:TF_VAR_jump_admin_password = "YourSecurePassword123!"`
   - **Bash:**  
     `export TF_VAR_jump_admin_password='YourSecurePassword123!'`

2. **Optional:** Set SSH public key for the Linux app VM (required if `vm-app` is present):

   - **PowerShell:**  
     `$env:TF_VAR_ssh_public_key = Get-Content $HOME\.ssh\id_rsa.pub`
   - **Bash:**  
     `export TF_VAR_ssh_public_key="$(cat ~/.ssh/id_rsa.pub)"`
   - Or set `ssh_public_key = "ssh-rsa AAAA..."` in the `vms.vm-app` block in `dev.tfvars`.

3. **Enabling or disabling resources:** In `dev.tfvars` all resource blocks are uncommented so they can be created when required. To skip a resource (e.g. due to quota or region), set its map to empty: `sql_servers = {}`, `app_services = {}`, `function_apps = {}`, `logic_apps = {}`, etc. If you set `sql_servers = {}` or `mysql_servers = {}`, also remove the `sql_pe` / `mysql_pe` entries from `private_endpoints` to avoid errors.

4. **Apply:**

   ```bash
   cd environments/dev
   terraform init
   terraform plan -var-file=dev.tfvars
   terraform apply -var-file=dev.tfvars
   ```

5. **Alternate region (East US 2):** To deploy a second dev stack in a different region with distinct resource names, use `dev-eastus2.tfvars`:

   ```bash
   terraform plan -var-file=dev-eastus2.tfvars
   terraform apply -var-file=dev-eastus2.tfvars
   ```

   That file uses **location = eastus2**, instance **003** / suffix **EUS2**, and address space **10.11.0.0/16** so it does not conflict with resources from `dev.tfvars` (eastus, 002, 10.10.0.0/16).

## Deployment troubleshooting (quota, names, regions)

If `terraform apply` fails with the errors below, use these fixes.

| Error | Cause | Fix |
|-------|--------|-----|
| **AKS:** VM size not in allowed list / quota | Default node pool SKU not available in your region or subscription | In `dev.tfvars` set `default_node_pool_vm_size = "Standard_F4s_v2"` (or another [allowed SKU](https://aka.ms/aks/quotas-skus-regions)). The module default is now `Standard_F4s_v2`. |
| **APIM:** `ServiceAlreadyExists` (409) | API Management name is globally unique and already taken | In `dev.tfvars` change `api_managements.main.name` to a unique value (e.g. `icr002-apim-bank-dev-eus1` or add your own suffix). |
| **Key Vault:** `VaultAlreadyExists` | Key Vault name is globally unique and already taken (or recently soft-deleted) | In `dev.tfvars` change `keyvaults.main.name` to a unique value (e.g. `icr002-kv-bank-dev-eus1` or add a unique suffix). If the vault was soft-deleted, purge it first or wait, or use another name. |
| **Redis:** `Name unavailable for reservation` | Redis name is globally reserved or already used | In `dev.tfvars` change `redis_caches.main.name` to a unique value (e.g. `icr002-redis-bank-dev-eus1`). |
| **App Service Plan:** `Current Limit (Basic VMs): 0` | Subscription has no Basic App Service quota in the region | Request [Basic/Standard quota](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/azure-subscription-service-limits#app-service-limits) for the region, or leave `app_services` (and `logic_apps` if they use that plan) commented out in `dev.tfvars`. |
| **Function App Plan:** `Current Limit (Dynamic VMs): 0` | Subscription has no Consumption/Dynamic VM quota | Request quota for Azure Functions (Consumption) in the region, or leave `function_apps` commented out in `dev.tfvars`. |
| **SQL Server:** `Provisioning is restricted in this region` | Azure SQL provisioning disabled in that region for your subscription | Use a different region in `rg.location` or leave `sql_servers` commented out. See [SQL quota](https://docs.microsoft.com/en-us/azure/sql-database/quota-increase-request). |
| **MySQL:** `Provisioning in requested region is not supported` | MySQL Flexible Server not available in region for your subscription | Use a [supported region](https://aka.ms/mysqlcapacity) or leave `mysql_servers` commented out in `dev.tfvars`. |

**Minimal deployable set:** With the current `dev.tfvars`, the following are enabled: RG, VNet, subnets, NSG, VMs (app + jump), storage, Key Vault, private endpoints, Redis, API Management, AKS. SQL, MySQL, App Service, Function App, and Logic App are left commented out to avoid quota/region errors until you request quota or switch region.

## Jump VM connectivity (from subnet-jump 10.10.3.0/24)

NSG rules are configured so that from the Jump VM you can reach:

| Resource           | Accessible from Jump VM | Reason |
| ------------------ | ----------------------- | ------ |
| Jump VM            | Yes                     | Public RDP allowed (restrict with `jump_rdp_source_cidr` in prod) |
| App VMs            | Yes                     | HTTPS (443) and SSH (22) from jump subnet allowed to subnet-app |
| Database           | Yes                     | SQL (1433) from jump subnet allowed to subnet-data |
| Private Endpoints  | Yes                     | VNet-wide rules for 443, 1433, 6380 on subnet-pe |
| AKS Nodes          | Yes                     | HTTPS (443) and SSH (22) from jump subnet allowed to subnet-aks |
| Storage (via PE)   | Yes                     | Via PE subnet rule (443) |
| Key Vault (via PE) | Yes                     | Via PE subnet rule (443) |

---

## Accessing the Jump VM (Windows)

The jump VM is a **Windows Server 2022** VM with a public IP for RDP.

### Get the public IP

After apply, run:

```bash
terraform output jump_vm_public_ip
```

Use this IP as the **Computer** in Remote Desktop Connection.

---

### Option A: RDP using local administrator

- Open **Remote Desktop Connection** (mstsc).
- **Computer:** `<jump_vm_public_ip>` (from the output above).
- **User:** `azureadmin` (or the value of `admin_username` for `vm-jump` in `dev.tfvars`).
- **Password:** The value you set for `TF_VAR_jump_admin_password`.

---

### Option B: RDP using Azure AD (recommended)

Azure AD login uses your Microsoft Entra (Azure AD) account—no local password on the VM. The jump VM has the **AADLoginForWindows** extension installed by Terraform.

#### Who has access by default

- The **identity that ran Terraform apply** (the Azure CLI user or service principal) is automatically assigned **Virtual Machine Administrator Login** on the jump VM. That identity can sign in to the VM with Azure AD.

#### Step-by-step: Connect with Azure AD

1. **Ensure you have the right role**  
   You need one of these roles on the **jump VM resource** (not the subscription):
   - **Virtual Machine Administrator Login** (full admin), or  
   - **Virtual Machine User Login** (standard user).

   If you ran `terraform apply` with your own Azure CLI login, you already have **Virtual Machine Administrator Login**. To grant another user:

   ```bash
   # Get the VM resource ID from Terraform output or Azure Portal, then:
   az role assignment create \
     --assignee "user@yourdomain.com" \
     --role "Virtual Machine Administrator Login" \
     --scope "/subscriptions/<subscription-id>/resourceGroups/<rg-name>/providers/Microsoft.Compute/virtualMachines/<vm-name>"
   ```

   Or in **Azure Portal:** VM → **Access control (IAM)** → **Add role assignment** → choose **Virtual Machine Administrator Login** or **Virtual Machine User Login** → assign to the user or group.

2. **Open Remote Desktop Connection**  
   - Windows: Run `mstsc` or use **Remote Desktop Connection**.
   - Mac: Install **Microsoft Remote Desktop** from the Mac App Store.

3. **Enter the computer address**  
   Use the jump VM public IP: `terraform output jump_vm_public_ip`.

4. **Sign in with Azure AD**  
   When prompted for credentials:
   - **User name:** Your Azure AD sign-in (e.g. `yourname@yourdomain.com` or `yourname@tenant.onmicrosoft.com`).
   - **Password:** Your Azure AD / Microsoft 365 password (or use Windows Hello / FIDO if configured).

   Do **not** use `azureadmin` or any local account here—use your **cloud account** (Azure AD UPN).

5. **Accept certificate warning (first time)**  
   If you see a certificate warning for the RDP connection, accept it to continue.

#### Requirements for Azure AD login

- The VM must have the **AADLoginForWindows** extension (already applied by this Terraform).
- Your Azure AD account must be in the same tenant as the subscription where the VM is deployed.
- The account must have **Virtual Machine Administrator Login** or **Virtual Machine User Login** on the VM (see step 1).
- Network: RDP (TCP 3389) must be allowed to the jump VM (NSG allows it in dev; in production restrict with `TF_VAR_jump_rdp_source_cidr`).

#### Troubleshooting Azure AD login

- **“Your credentials did not work”**  
  Confirm your account has one of the VM login roles on the VM (step 1). Wait a few minutes after role assignment.

- **“The logon attempt failed”**  
  Ensure you are using your **Azure AD** email (e.g. `user@domain.com`), not a local username like `azureadmin`.

- **Need to add more users**  
  Add a role assignment on the VM for **Virtual Machine Administrator Login** or **Virtual Machine User Login** (Portal IAM or `az role assignment create` as above).

---

### Production: Restrict RDP source

In production, do not allow RDP from the whole internet. Set **`TF_VAR_jump_rdp_source_cidr`** to your VPN or bastion CIDR (e.g. `x.x.x.x/32`) so only that range can reach the jump VM.

## Key Vault Secrets (scalable, multi-purpose)

Secrets are defined in a **map** in `dev.tfvars` (`key_vault_secrets`). Add one entry per secret; each can target any Key Vault via `key_vault_key` (e.g. `"main"`). Use for:

- **SQL / MySQL connection strings** – `secret_name` (e.g. `SqlConnectionString`), `content_type = "text/plain"`
- **Redis, API keys, certificates** – same pattern; set `content_type` as needed or leave null
- **Multiple Key Vaults** – use different `key_vault_key` values when you have more than one Key Vault in `keyvaults`

Set `secret_value` via `TF_VAR_*` or a sensitive variable in production; do not commit real values. The Terraform run identity needs **Key Vault Secrets Officer** on the vault (granted in `rbac.tf`).

## Private DNS Zones (scalable)

There are two ways private DNS zones are used:

1. **PE-backed zones (automatic)** – When you add a private endpoint for storage, keyvault, sql, mysql, redis, acr, or app_service, the corresponding zone (e.g. `privatelink.blob.core.windows.net`) is created automatically in `main.tf` and linked to the first VNet. No extra config needed.

2. **Extra zones (scalable map)** – For any **additional** zones (e.g. PostgreSQL `privatelink.postgres.database.azure.com`, or a custom zone), use **`private_dns_zones`** in `dev.tfvars`. It is a **map**: add one entry per zone. Each entry has `zone_name`, `vnet_keys` (list of VNet keys to link), and optional `registration_enabled`. Example:

   ```hcl
   private_dns_zones = {
     sql    = { zone_name = "privatelink.database.windows.net",    vnet_keys = ["main"] }
     postgres = { zone_name = "privatelink.postgres.database.azure.com", vnet_keys = ["main"] }
   }
   ```

   Do not duplicate zone names that are already created for PEs (blob, vault, sql, mysql, redis, acr, webapp); those are created inline when a PE of that type exists.

## Private Endpoints (all PaaS – scalable)

Private Endpoints are defined in a **map** in `dev.tfvars` (`private_endpoints`). You can add one entry per PaaS resource; the code supports all types below. The corresponding **Private DNS zone** is created automatically when the first PE of that type is added, so FQDNs resolve to the private IP.

| target_type   | PaaS resource (target_key) | subresource_name | Private DNS zone (auto-created) |
|---------------|----------------------------|------------------|----------------------------------|
| `storage`     | `storage_accounts`         | `blob`, `file`, `queue`, `table` | privatelink.blob.core.windows.net |
| `keyvault`    | `keyvaults`                | `vault`          | privatelink.vaultcore.azure.net |
| `sql`         | `sql_servers`              | `sqlServer`      | privatelink.database.windows.net |
| `mysql`       | `mysql_servers`            | `mysqlServer`    | privatelink.mysql.database.azure.com |
| `redis`       | `redis_caches`             | `redisCache`     | privatelink.redis.cache.windows.net |
| `acr`         | `registries`               | `registry`       | privatelink.azurecr.io |
| `app_service` | `app_services`             | `sites`          | privatelink.azurewebsites.net |

**Adding a PE:** Ensure the target resource exists (e.g. `sql_servers["main"]`) and add a new key under `private_endpoints` with `target_type`, `target_key`, `vnet_key`, `subnet_key`, and `subresource_name` as in the table. No code change is required.

## Naming convention (Internal / Client)

**Pattern:** `ICR-<nnn>-Azure-<INT|CLT>-<ResourceType>-<Workload>`

- **Internal:** INT (e.g. VM `ICR-002-Azure-LIN-INT-IT-Sonar`, Web App `ICR-055-Azure-INT-Web-App-RAT-QA`)
- **Client:** CLT (e.g. Web App `ICR-051-Azure-CLT-Web-App-Cook-Medical`, VM `ICR-045-Azure-WIN-CLI-Starting-Point`)
- This dev env uses **INT**, instance **002**, workload **Bank-Dev**

| Resource          | Example (Internal dev)                    | Notes                          |
|-------------------|------------------------------------------|--------------------------------|
| VM (Linux)        | `ICR-002-Azure-LIN-INT-Bank-App`         | LIN = Linux                    |
| VM (Jump)         | `icr-002-Azure-WIN-INT-Bank-Jump`        | WIN = Windows; RDP access      |
| VNet              | `ICR-002-Azure-INT-VNet-Bank-Dev`        |                                |
| Storage Account   | `ICR002INTStgBank`                       | No hyphens; max 24 chars      |
| Key Vault         | `ICR-002-Azure-INT-KV-Bank`              | Max 24 chars                   |
| Private Endpoint  | `ICR-002-Azure-INT-PE-Stg-Bank`          |                                |
| SQL Server        | `ICR-002-Azure-INT-SQL-Bank-Dev`         |                                |
| Redis             | `ICR-002-Azure-INT-Redis-Bank-Dev`       |                                |
| MySQL             | `ICR-002-Azure-INT-MySQL-Bank-Dev`       |                                |
| Web App           | `ICR-002-Azure-INT-Web-App-Bank-Dev`     |                                |
| App Service Plan  | `ICR-002-Azure-INT-App-Srv-Plan-Bank-Dev`|                               |
| Function App      | `ICR-002-Azure-INT-Func-App-Bank-Dev`    |                                |
| Logic App         | `ICR-002-Azure-INT-Logic-App-Bank-Dev`   |                                |
| API Management    | `ICR-002-Azure-INT-APIM-Bank-Dev`        |                                |
| AKS               | `ICR-002-Azure-INT-AKS-Bank-Dev`         |                                |
| Container Registry| `ACRICR002INTBank`                      | Alphanumeric only; 5–50 chars |

Storage and ACR use no hyphens to meet Azure rules. Change names in `dev.tfvars` as needed; ensure global uniqueness where required.

## Outputs

After apply, Terraform outputs resource group name/id, VNet/subnet IDs, VM private IPs, **jump_vm_public_ip**, **jump_vm_connection_hint**, storage account names, and Key Vault names/URIs.
