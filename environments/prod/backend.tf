# =============================================================================
# Terraform Backend — Production (Security Baseline)
# =============================================================================
# INITIALLY: Local state is used (backend block below is commented out).
# State is stored in ./terraform.tfstate. Do not commit state to Git.
#
# When ready for remote state (per SECURITY_BASELINES.md):
# • Uncomment the terraform/backend block below.
# • Create backend storage: RG + Storage Account + container (e.g. "tfstate").
# • Run: terraform init -reconfigure \
#     -backend-config="resource_group_name=rg-tfstate-prod" \
#     -backend-config="storage_account_name=<unique>" \
#     -backend-config="container_name=tfstate"
# • State storage: HTTPS only, TLS 1.2+; restrict access via RBAC to CI/SP only.
# • Optional: private endpoint for state storage (no public access).
# • Key below: prod.terraform.tfstate (separate key per env).
# =============================================================================

# terraform {
#   backend "azurerm" {
#     # Required: set via -backend-config or backend config file (do not commit secrets)
#     # resource_group_name  = "rg-tfstate-prod"
#     # storage_account_name = "tfstate<unique>"
#     # container_name       = "tfstate"
#     key = "prod.terraform.tfstate"
#     # use_azuread = true   # Prefer Azure AD auth over access key when supported
#   }
# }
