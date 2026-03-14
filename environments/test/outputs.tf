# Dev environment outputs

output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.rg.name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = module.rg.id
}
