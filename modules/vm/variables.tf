variable "name" {
  description = "Name of the virtual machine"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the VM NIC"
  type        = string
}

variable "size" {
  description = "VM size (e.g. Standard_B2s)"
  type        = string
  default     = "Standard_B2s"
}

variable "os_type" {
  description = "OS type: linux or windows"
  type        = string
  default     = "linux"

  validation {
    condition     = contains(["linux", "windows"], var.os_type)
    error_message = "os_type must be linux or windows."
  }
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
}

variable "admin_password" {
  description = "Admin password for Windows VM (required). For Linux VM optional: use for password login and/or together with ssh_public_key. Must meet Azure complexity requirements."
  type        = string
  sensitive   = true
  default     = null

  validation {
    condition     = var.os_type != "windows" || var.admin_password != null
    error_message = "admin_password is required when os_type is windows. Set it before plan/apply: PowerShell: $env:TF_VAR_jump_admin_password = 'YourPassword'; Bash: export TF_VAR_jump_admin_password='YourPassword' (or set admin_password in the VM config in tfvars)."
  }
  validation {
    condition     = var.os_type != "linux" || (coalesce(var.ssh_public_key, "") != "" || (var.admin_password != null && var.admin_password != ""))
    error_message = "For Linux VMs, at least one of ssh_public_key or admin_password must be set (SSH key login, password login, or both)."
  }
}

variable "ssh_public_key" {
  description = "SSH public key for Linux VM. Optional if admin_password is set (Linux can use password-only, SSH-only, or both)."
  type        = string
  default     = null
}

variable "create_public_ip" {
  description = "Whether to create a public IP for the VM"
  type        = bool
  default     = false
}

variable "os_disk_type" {
  description = "OS disk storage account type"
  type        = string
  default     = "Standard_LRS"
}

variable "os_disk_size_gb" {
  description = "OS disk size in GB"
  type        = number
  default     = 128
}

variable "os_disk_name" {
  description = "Optional name for the OS disk. If null, Azure generates a name."
  type        = string
  default     = null
}

variable "delete_os_disk_on_termination" {
  description = "Reserved for tfvars/documentation. For azurerm_linux_virtual_machine/azurerm_windows_virtual_machine, OS disk deletion is controlled via provider features: features { virtual_machine { delete_os_disk_on_deletion = true } } (default true = delete disk when VM is destroyed)."
  type        = bool
  default     = true
}

variable "computer_name" {
  description = "Optional computer name (hostname). If null, derived from VM name (Windows: truncated to 15 chars per NetBIOS limit). Omit in tfvars to leave unset."
  type        = string
  default     = null
}

variable "custom_data" {
  description = "Optional base64-encoded custom data (cloud-init for Linux, script for Windows)."
  type        = string
  default     = null
  sensitive   = true
}

variable "encryption_at_host_enabled" {
  description = "Enable encryption at host for the VM (security baseline for sensitive workloads)."
  type        = bool
  default     = false
}

variable "source_image_id" {
  description = "Custom image ID (overrides source_image_reference when set)"
  type        = string
  default     = null
}

variable "image_publisher" {
  description = "Image publisher (when not using source_image_id)"
  type        = string
  default     = "Canonical"
}

variable "image_offer" {
  description = "Image offer"
  type        = string
  default     = "0001-com-ubuntu-server-jammy"
}

variable "image_sku" {
  description = "Image SKU"
  type        = string
  default     = "22_04-lts"
}

variable "image_version" {
  description = "Image version"
  type        = string
  default     = "latest"
}

# Windows image (used when os_type = "windows")
variable "windows_image_publisher" {
  description = "Windows image publisher (when os_type is windows)"
  type        = string
  default     = "MicrosoftWindowsServer"
}

variable "windows_image_offer" {
  description = "Windows image offer"
  type        = string
  default     = "WindowsServer"
}

variable "windows_image_sku" {
  description = "Windows image SKU"
  type        = string
  default     = "2022-datacenter-azure-edition"
}

variable "windows_image_version" {
  description = "Windows image version"
  type        = string
  default     = "latest"
}

# Optional: security baseline – boot diagnostics (RESOURCE_CONTROLS_SHEET). Enable via tfvars.
variable "boot_diagnostics_enabled" {
  description = "Enable boot diagnostics (use storage_uri or null for managed). Set true in tfvars for troubleshooting."
  type        = bool
  default     = false
}

variable "boot_diagnostics_storage_uri" {
  description = "Storage account URI for boot diagnostics. Leave null for Azure-managed when boot_diagnostics_enabled is true."
  type        = string
  default     = null
}

# Optional: availability zone (1, 2, 3) for HA. Set in tfvars for prod.
variable "availability_zone" {
  description = "Availability zone for the VM (1, 2, or 3). Leave null for no zone."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}


