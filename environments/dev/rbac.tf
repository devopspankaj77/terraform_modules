# data "azurerm_client_config" "current" {}

resource "azurerm_role_assignment" "terraform_kv_secrets_officer" {
  for_each = module.keyvaults

  scope                = each.value.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Grant each VM access to Key Vault (only when keyvaults.main is defined)
resource "azurerm_role_assignment" "vm_kv_access" {
  for_each = contains(keys(var.keyvaults), "main") ? module.vms : {}

  scope                = module.keyvaults["main"].keyvault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = each.value.principal_id
}