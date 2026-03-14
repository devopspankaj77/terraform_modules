# Virtual Machine Module
# Creates Azure Linux or Windows VM with optional managed disk

locals {
  # Optional computer_name: when null, use VM name; Windows hostname capped at 15 chars (NetBIOS)
  effective_computer_name_linux  = coalesce(var.computer_name, var.name)
  effective_computer_name_win   = (length(coalesce(var.computer_name, var.name)) > 15) ? substr(coalesce(var.computer_name, var.name), 0, 15) : coalesce(var.computer_name, var.name)
  # Linux auth: SSH-only, password-only, or BOTH (set both ssh_public_key and admin_password in tfvars)
  linux_password_auth_enabled = var.os_type == "linux" && var.admin_password != null && var.admin_password != ""
  linux_ssh_key_provided     = var.os_type == "linux" && coalesce(var.ssh_public_key, "") != ""
}

# Public IP only when required (e.g. jump box); Standard SKU per security baseline
resource "azurerm_public_ip" "main" {
  for_each            = var.create_public_ip ? toset(["pip"]) : toset([])
  name                = "${var.name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}


##################################
# Network Interface
##################################
resource "azurerm_network_interface" "main" {
  name                = "${var.name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.create_public_ip ? azurerm_public_ip.main["pip"].id : null
  }
}
resource "azurerm_linux_virtual_machine" "main" {
  for_each = var.os_type == "linux" ? toset(["linux"]) : toset([])

  name                           = var.name
  location                       = var.location
  resource_group_name            = var.resource_group_name
  size                           = var.size
  admin_username                 = var.admin_username
  computer_name                  = local.effective_computer_name_linux
  zone                           = var.availability_zone
  tags                           = var.tags
  custom_data                    = var.custom_data
  encryption_at_host_enabled     = var.encryption_at_host_enabled

  # Linux login: SSH-only | password-only | BOTH (ssh_key + password)
  # When admin_password is set → password auth enabled (password-only or both).
  # When ssh_public_key is set → admin_ssh_key block added (SSH-only or both).
  disable_password_authentication = !local.linux_password_auth_enabled
  admin_password                 = local.linux_password_auth_enabled ? var.admin_password : null

  dynamic "admin_ssh_key" {
    for_each = local.linux_ssh_key_provided ? [1] : []
    content {
      username   = var.admin_username
      public_key = var.ssh_public_key
    }
  }

  network_interface_ids = [azurerm_network_interface.main.id]

  os_disk {
    name                 = coalesce(var.os_disk_name, "${var.name}-osdisk")
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_type
    disk_size_gb         = var.os_disk_size_gb
    # delete_os_disk_on_termination: use provider features.virtual_machine.delete_os_disk_on_deletion (not supported on this resource)
  }

  dynamic "boot_diagnostics" {
    for_each = var.boot_diagnostics_enabled ? [1] : []
    content {
      storage_account_uri = var.boot_diagnostics_storage_uri
    }
  }

  source_image_id = var.source_image_id

  dynamic "source_image_reference" {
    for_each = var.source_image_id == null ? [1] : []
    content {
      publisher = var.image_publisher
      offer     = var.image_offer
      sku       = var.image_sku
      version   = var.image_version
    }
  }

  identity {
    type = "SystemAssigned"
  }
}

# Azure AD Login Extension



resource "azurerm_virtual_machine_extension" "aad_login" {
  for_each = var.os_type == "linux" ? toset(["aad"]) : toset([])

  name                 = "AADLoginForLinux"
  virtual_machine_id   = azurerm_linux_virtual_machine.main["linux"].id
  publisher            = "Microsoft.Azure.ActiveDirectory"
  type                 = "AADSSHLoginForLinux"
  type_handler_version = "1.0"
}

##################################
# Windows Virtual Machine
##################################
resource "azurerm_windows_virtual_machine" "main" {
  for_each = var.os_type == "windows" ? toset(["windows"]) : toset([])

  name                         = var.name
  location                     = var.location
  resource_group_name          = var.resource_group_name
  size                         = var.size
  computer_name                = local.effective_computer_name_win
  zone                         = var.availability_zone
  admin_username               = var.admin_username
  admin_password               = var.admin_password
  network_interface_ids        = [azurerm_network_interface.main.id]
  tags                         = var.tags
  custom_data                  = var.custom_data
  encryption_at_host_enabled   = var.encryption_at_host_enabled

  os_disk {
    name                 = coalesce(var.os_disk_name, "${var.name}-osdisk")
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_type
    disk_size_gb         = var.os_disk_size_gb
    # delete_os_disk_on_termination: use provider features.virtual_machine.delete_os_disk_on_deletion (not supported on this resource)
  }

  dynamic "boot_diagnostics" {
    for_each = var.boot_diagnostics_enabled ? [1] : []
    content {
      storage_account_uri = var.boot_diagnostics_storage_uri
    }
  }

  source_image_id = var.source_image_id

  dynamic "source_image_reference" {
    for_each = var.source_image_id == null ? [1] : []
    content {
      publisher = var.windows_image_publisher
      offer     = var.windows_image_offer
      sku       = var.windows_image_sku
      version   = var.windows_image_version
    }
  }

  identity {
    type = "SystemAssigned"
  }
}

# Azure AD Login Extension for Windows (enables RDP via Azure AD)
resource "azurerm_virtual_machine_extension" "aad_login_windows" {
  for_each = var.os_type == "windows" ? toset(["aad"]) : toset([])

  name                 = "AADLoginForWindows"
  virtual_machine_id   = azurerm_windows_virtual_machine.main["windows"].id
  publisher            = "Microsoft.Azure.ActiveDirectory"
  type                 = "AADLoginForWindows"
  type_handler_version = "1.0"
}