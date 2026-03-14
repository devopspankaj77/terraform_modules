# Virtual Network Module
# Creates VNet, NSGs, Subnets, optional Public IPs, and Private Endpoint subnet

resource "azurerm_virtual_network" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  tags                = var.tags
}

# NSG: one shared or one per subnet
locals {
  nsg_keys = var.create_nsg ? (var.nsg_per_subnet ? keys(var.subnets) : ["shared"]) : []
}

resource "azurerm_network_security_group" "main" {
  for_each = toset(local.nsg_keys)

  name                = var.nsg_per_subnet ? "${var.name}-${each.value}-nsg" : "${var.name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# resource "azurerm_network_security_rule" "rules" {
#   for_each = var.create_nsg && !var.nsg_per_subnet ? var.nsg_rules : {}

#   name                        = each.key
#   priority                    = each.value.priority
#   direction                   = each.value.direction
#   access                      = each.value.access
#   protocol                    = each.value.protocol
#   source_port_range           = lookup(each.value, "source_port_range", "*")
#   destination_port_range      = lookup(each.value, "destination_port_range", "*")
#   source_address_prefix       = lookup(each.value, "source_address_prefix", "*")
#   destination_address_prefix  = lookup(each.value, "destination_address_prefix", "*")
#   resource_group_name         = var.resource_group_name
#   network_security_group_name = azurerm_network_security_group.main["shared"].name
# }
resource "azurerm_network_security_rule" "per_nsg_rules" {
  for_each = var.create_nsg && var.nsg_per_subnet ? merge([
    for subnet_name, rules in var.nsg_rules : {
      for rule_name, rule in rules :
      "${subnet_name}.${rule_name}" => {
        subnet_name = subnet_name
        rule_name   = rule_name
        rule        = rule
      }
    }
  ]...) : {}

  name                         = each.value.rule_name
  priority                     = each.value.rule.priority
  direction                    = each.value.rule.direction
  access                       = each.value.rule.access
  protocol                     = each.value.rule.protocol
  # Use singular form: SourcePortRanges cannot be "*"; use source_port_range = "*" for any
  source_port_range            = coalesce(lookup(each.value.rule, "source_port_range", "*"), "*")
  destination_port_range       = coalesce(lookup(each.value.rule, "destination_port_range", "*"), "*")
  # Use source_address_prefixes when provided (e.g. corporate IPs for RDP); otherwise source_address_prefix
  source_address_prefix        = length(coalesce(lookup(each.value.rule, "source_address_prefixes", []), [])) > 0 ? null : coalesce(lookup(each.value.rule, "source_address_prefix", "*"), "*")
  source_address_prefixes      = length(coalesce(lookup(each.value.rule, "source_address_prefixes", []), [])) > 0 ? coalesce(lookup(each.value.rule, "source_address_prefixes", []), []) : null
  destination_address_prefix   = coalesce(lookup(each.value.rule, "destination_address_prefix", "*"), "*")

  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.main[each.value.subnet_name].name
}


resource "azurerm_subnet" "subnets" {
  for_each = var.subnets

  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = each.value.address_prefixes

  # Subnets used for private endpoints (or AzureBastionSubnet) get private_endpoint_network_policies = Disabled
  private_endpoint_network_policies = (each.key == "AzureBastionSubnet" || contains(var.subnets_allow_private_endpoint, each.key)) ? "Disabled" : "Enabled"
}

resource "azurerm_subnet_network_security_group_association" "main" {

  for_each = {
    for k, v in azurerm_subnet.subnets :
    k => v if k != "AzureBastionSubnet"
  }

  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.main[each.key].id
}

# Optional: Public IP (e.g. for NAT Gateway or VMs)
resource "azurerm_public_ip" "main" {
  for_each = var.public_ips

  name                = each.key
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = each.value.allocation_method
  sku                 = lookup(each.value, "sku", "Basic")
  tags                = var.tags
}

# Subnet for Private Endpoints (required for many PaaS private endpoints)
resource "azurerm_subnet" "private_endpoint" {
  for_each = var.create_private_endpoint_subnet ? toset(["pe"]) : toset([])

  name                 = var.private_endpoint_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.private_endpoint_subnet_prefix]

  private_endpoint_network_policies = "Disabled"
}



