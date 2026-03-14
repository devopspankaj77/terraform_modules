# Private Endpoint Module
# Creates a private endpoint for an Azure PaaS resource (Storage, Key Vault, SQL, etc.)

resource "azurerm_private_endpoint" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.name}-psc"
    private_connection_resource_id = var.target_resource_id
    is_manual_connection           = false
    subresource_names              = [var.subresource_name]
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id != null ? [1] : []
    content {
      name                 = "${var.name}-dns"
      private_dns_zone_ids = [var.private_dns_zone_id]
    }
  }
}
