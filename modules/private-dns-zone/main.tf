# Private DNS Zone Module (reusable)
# Create a private DNS zone and link to one or more VNets (e.g. for SQL, MySQL, Redis, ACR, App Service PE)

resource "azurerm_private_dns_zone" "main" {
  name                = var.zone_name
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# resource "azurerm_private_dns_zone_virtual_network_link" "main" {
#   for_each = toset(var.virtual_network_ids)

#   name                  = "${replace(var.zone_name, ".", "-")}-link-${md5(each.value)}"
#   resource_group_name   = var.resource_group_name
#   private_dns_zone_name = azurerm_private_dns_zone.main.name
#   virtual_network_id    = each.value
#   registration_enabled  = var.registration_enabled
#   tags                  = var.tags
# }


resource "azurerm_private_dns_zone_virtual_network_link" "main" {

  for_each = { for idx, vnet in var.virtual_network_ids : idx => vnet }

  name                  = "link-${each.key}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.main.name
  virtual_network_id    = each.value
}