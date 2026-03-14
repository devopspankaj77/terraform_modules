# Azure Database for MySQL Flexible Server Module

resource "azurerm_mysql_flexible_server" "main" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  version             = var.mysql_version
  sku_name            = var.sku_name
  zone                = var.zone
  tags                = var.tags

  administrator_login    = var.administrator_login
  administrator_password = var.administrator_password

  storage {
    size_gb           = var.storage_size_gb
    iops              = var.storage_iops
    auto_grow_enabled = var.storage_auto_grow_enabled
  }

  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled

  dynamic "high_availability" {
    for_each = var.high_availability_mode != null && var.high_availability_mode != "" && var.high_availability_mode != "Disabled" ? [1] : []
    content {
      mode = var.high_availability_mode
    }
  }

  dynamic "maintenance_window" {
    for_each = var.maintenance_window != null ? [var.maintenance_window] : []
    content {
      day_of_week  = maintenance_window.value.day_of_week
      start_hour   = maintenance_window.value.start_hour
      start_minute = maintenance_window.value.start_minute
    }
  }
}

resource "azurerm_mysql_flexible_database" "databases" {
  for_each = var.databases

  name                = each.key
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.main.name
  charset             = lookup(each.value, "charset", "utf8mb4")
  collation           = lookup(each.value, "collation", "utf8mb4_unicode_ci")
}

resource "azurerm_mysql_flexible_server_firewall_rule" "rules" {
  for_each = var.firewall_rules

  name                = each.key
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.main.name
  start_ip_address    = each.value.start_ip_address
  end_ip_address      = each.value.end_ip_address
}
