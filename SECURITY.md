# Security Practices

Follow these practices when using this Terraform project. See also [SECURITY_BASELINES.md](SECURITY_BASELINES.md) for a full checklist.

## Secrets

- **Do not** put passwords, keys, or connection strings in committed `.tf` or `.tfvars` files.
- Use **environment variables** (e.g. `TF_VAR_sql_admin_password`, `TF_VAR_administrator_password`) or **Azure Key Vault** (e.g. `data "azurerm_key_vault_secret"`) for SQL, MySQL, and any app secrets.
- Variables `sql_servers` and `mysql_servers` are marked `sensitive = true`; prefer passing secrets via `TF_VAR_*` or CI secret variables.

## Apply in Production

- **Do not** run `terraform apply -auto-approve` in production or in unattended pipelines without approval gates.
- Use manual apply or a CI/CD pipeline with a required approval step before apply.

## Network (Jump Box)

- The jump VM can be **Linux (SSH)** or **Windows (RDP)**. Dev uses a Windows jump VM by default.
- **Windows jump:** In production, restrict RDP to the jump subnet by setting **`TF_VAR_jump_rdp_source_cidr`** to your VPN or bastion CIDR (e.g. `x.x.x.x/32`). Set **`TF_VAR_jump_admin_password`** for the local admin (do not commit).
- **Linux jump:** Restrict SSH by setting **`TF_VAR_jump_ssh_source_cidr`** to your VPN or bastion CIDR.
- Leaving the CIDR unset uses the value from `nsg_rules` in tfvars (e.g. `*` in dev).

## Subscription and Backend

- Use **`ARM_SUBSCRIPTION_ID`** (or Azure CLI default); do not hardcode subscription IDs in code.
- Enable a **remote backend** (e.g. `azurerm`) for shared/CI use and lock down state storage (RBAC, private endpoint). Configure in `environments/<env>/backend.tf` when ready.

## Optional: Ignore tfvars in Git

If your `*.tfvars` files contain environment-specific or secret values, consider adding to `.gitignore`:

```
# Uncomment if tfvars hold secrets:
# *.tfvars
```

Use a `*.tfvars.example` (without real secrets) and inject values via env or a secret store.
