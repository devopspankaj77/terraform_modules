variable "name" {
  description = "Name of the virtual network"
  type        = string
}

variable "location" {
  description = "Azure region for the virtual network"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
}

variable "subnets" {
  description = "Map of subnet names to configuration (address_prefixes)"
  type        = map(object({
    address_prefixes = list(string)
  }))
  default = {}
}

# SECURITY_BASELINES 7.2: Private endpoint subnet with network policies disabled
variable "subnets_allow_private_endpoint" {
  description = "Subnet names used for private endpoints; these get private_endpoint_network_policies = Disabled (required for PaaS PEs). AzureBastionSubnet is always set to Disabled automatically."
  type        = set(string)
  default     = []
}

variable "create_nsg" {
  description = "Create a network security group (shared or per-subnet)"
  type        = bool
  default     = true
}

variable "nsg_per_subnet" {
  description = "Create one NSG per subnet; if false, one shared NSG"
  type        = bool
  default     = false
}

# variable "nsg_rules" {
#   description = "NSG rules (used only when create_nsg=true and nsg_per_subnet=false)"
#   type = map(object({
#     priority                   = number
#     direction                  = string
#     access                     = string
#     protocol                   = string
#     source_port_range          = optional(string, "*")
#     destination_port_range     = optional(string, "*")
#     source_address_prefix      = optional(string, "*")
#     destination_address_prefix = optional(string, "*")
#   }))
#   default = {}
# }

variable "public_ips" {
  description = "Map of public IP names to { allocation_method, sku }"
  type = map(object({
    allocation_method = string
    sku              = optional(string, "Basic")
  }))
  default = {}
}

variable "create_private_endpoint_subnet" {
  description = "Create a dedicated subnet for private endpoints"
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_name" {
  description = "Name of the private endpoint subnet"
  type        = string
  default     = "private-endpoints"
}

variable "private_endpoint_subnet_prefix" {
  description = "Address prefix for private endpoint subnet"
  type        = string
  default     = "10.0.100.0/24"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}







variable "nsg_rules" {
  description = "NSG rules per subnet NSG. Use source_address_prefix (single CIDR) or source_address_prefixes (list of CIDRs), e.g. for RDP from corporate IPs."
  type = map(
    map(object({
      priority                    = number
      direction                   = string
      access                      = string
      protocol                    = string
      source_port_range           = optional(string)
      destination_port_range      = optional(string)
      source_address_prefix       = optional(string)
      source_address_prefixes     = optional(list(string)) # When set, source_address_prefix is ignored (use for multiple IPs e.g. corporate RDP)
      destination_address_prefix  = optional(string)
    }))
  )
  default = {}
}



