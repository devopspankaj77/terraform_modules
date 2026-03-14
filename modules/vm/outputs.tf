# # output "vm_id" {
# #   description = "Virtual Machine ID"
# #   value       = azurerm_linux_virtual_machine.main[0].id
# # }

# # output "vm_name" {
# #   description = "Virtual Machine Name"
# #   value       = azurerm_linux_virtual_machine.main[0].name
# # }

output "private_ip_address" {
  value = azurerm_network_interface.main.private_ip_address
}

# # output "principal_id" {
# #   description = "Managed Identity Principal ID"
# #   value       = azurerm_linux_virtual_machine.main[0].identity[0].principal_id
# # }




# ##################################
# # VM ID
# ##################################

# output "vm_id" {
#   description = "ID of the VM"
#   value = try(
#     azurerm_linux_virtual_machine.main[0].id,
#     azurerm_windows_virtual_machine.main[0].id
#   )
# }

# ##################################
# # VM Name
# ##################################

# output "vm_name" {
#   description = "Name of the VM"
#   value = try(
#     azurerm_linux_virtual_machine.main[0].name,
#     azurerm_windows_virtual_machine.main[0].name
#   )
# }

# ##################################
# # Managed Identity Principal ID
# ##################################

# output "principal_id" {
#   description = "Managed identity principal ID"
#   value = try(
#     azurerm_linux_virtual_machine.main[0].identity[0].principal_id,
#     azurerm_windows_virtual_machine.main[0].identity[0].principal_id
#   )
# }


##################################
# VM ID
##################################

output "vm_id" {
  description = "ID of the VM"
  value       = try(azurerm_linux_virtual_machine.main["linux"].id, azurerm_windows_virtual_machine.main["windows"].id)
}

##################################
# VM Name
##################################

output "vm_name" {
  description = "Name of the VM"
  value       = try(azurerm_linux_virtual_machine.main["linux"].name, azurerm_windows_virtual_machine.main["windows"].name)
}

##################################
# Managed Identity Principal ID
##################################

output "principal_id" {
  description = "Managed identity principal ID"
  value       = try(azurerm_linux_virtual_machine.main["linux"].identity[0].principal_id, azurerm_windows_virtual_machine.main["windows"].identity[0].principal_id)
}

##################################
# Public IP (for jump VM access guidance)
##################################

output "public_ip_address" {
  description = "Public IP address of the VM (when create_public_ip is true)"
  value       = var.create_public_ip ? azurerm_public_ip.main["pip"].ip_address : null
}