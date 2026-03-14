resource "azurerm_public_ip" "bastion" {
  name                = var.public_ip_name
  location            = var.location
  resource_group_name = var.resource_group_name

  allocation_method = "Static"
  sku               = "Standard"

  tags = var.tags
}

resource "azurerm_bastion_host" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku                 = var.sku
  scale_units         = var.scale_units

  copy_paste_enabled  = var.copy_paste_enabled
  file_copy_enabled   = var.file_copy_enabled
  tunneling_enabled   = var.tunneling_enabled

  ip_configuration {
    name                 = "bastion-ipconfig"
    subnet_id            = var.subnet_id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }

  tags = var.tags
}

