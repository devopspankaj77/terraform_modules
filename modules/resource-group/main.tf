# Resource Group Module

resource "azurerm_resource_group" "main" {
  name     = var.name
  location = var.location
  tags     = var.tags
}

# Optional: management lock (enable via create_lock = true in tfvars)
resource "azurerm_management_lock" "main" {
  for_each = var.create_lock ? toset(["lock"]) : toset([])

  name       = "${var.name}-lock"
  scope      = azurerm_resource_group.main.id
  lock_level = var.lock_level
}
