# Terraform Enterprise Module Structure

Reusable Terraform layout for Azure with environment-specific configs and shared naming/tagging.

## Structure

```
terraform-enterprise/
├── modules/              # Reusable resource modules
│   ├── vnet/
│   ├── vm/
│   ├── storage-account/
│   ├── sql/
│   ├── keyvault/
│   ├── aks/
│   ├── app-service/
│   ├── registry/
│   ├── redis/
│   ├── mysql/
│   ├── function-app/
│   ├── logic-app/
│   ├── api-management/
│   └── private-endpoint/
├── environments/         # Per-environment root modules (resources = what’s in main.tf)
│   ├── dev/              # RG, VNet, Storage, Key Vault
│   ├── uat/              # dev + App Service, Redis
│   └── prod/             # full set + SQL, VM, AKS, Registry, MySQL, Function App, Logic App, APIM, Private Endpoint
└── global/               # Shared naming, tags, and policies
    ├── naming.tf
    ├── tags.tf
    └── policies.tf
```

## Quick Start

1. **Configure backend**  
   Edit `environments/<env>/backend.tf` and set your Azure Storage (or other) backend.

2. **Apply dev**
   ```bash
   cd environments/dev
   terraform init
   terraform plan -var-file=dev.tfvars
   terraform apply -var-file=dev.tfvars
   ```
   **Security:** Do **not** use `-auto-approve` in production; use manual or gated pipeline apply. See [SECURITY.md](SECURITY.md).

3. **UAT / Prod**
   ```bash
   cd environments/uat
   terraform init -backend-config=backend.uat.hcl   # if using .hcl backend config
   terraform plan -var-file=uat.tfvars
   terraform apply -var-file=uat.tfvars
   ```

## Modules

| Module | Description |
|--------|-------------|
| **vnet** | Virtual Network + subnets |
| **vm** | Linux or Windows VM with NIC (optional public IP) |
| **storage-account** | Storage account + optional containers |
| **sql** | Azure SQL Server + databases + firewall rules |
| **keyvault** | Key Vault with access policies or RBAC |
| **aks** | AKS cluster + default and user node pools |

**Which resources exist** is defined in each environment’s `main.tf`: add or remove module blocks. No toggle variables. **Variables** hold only configuration (names, SKUs, addresses, etc.); set values in `*.tfvars`.

## Global

- **naming.tf** – Naming conventions and `organization_name` / `environment` usage.
- **tags.tf** – Default tags (Environment, ManagedBy, Project, Owner).
- **policies.tf** – Placeholder for shared policy variables.

Copy or reference these patterns in each environment’s `main.tf` (as in dev/uat/prod).

## Requirements

- Terraform >= 1.0
- Azure Provider ~> 3.0
- Azure CLI login: `az login`



terraform plan -var-file="dev.tfvars"

# Dev only: avoid -auto-approve in production (see SECURITY.md)
terraform apply -var-file=dev.tfvars