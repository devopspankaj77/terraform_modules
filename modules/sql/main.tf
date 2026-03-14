# Azure SQL Module
# Creates Azure SQL Server and optional database(s)

resource "azurerm_mssql_server" "main" {
  name                         = var.server_name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = var.sql_version
  administrator_login          = var.admin_username
  administrator_login_password = var.admin_password
  tags                         = var.tags

  minimum_tls_version = var.min_tls_version

  dynamic "azuread_administrator" {
    for_each = var.azuread_administrator != null ? [var.azuread_administrator] : []
    content {
      login_username = azuread_administrator.value.login
      object_id      = azuread_administrator.value.object_id
      tenant_id      = azuread_administrator.value.tenant_id
    }
  }

  # Extended auditing: use azurerm_mssql_server_extended_auditing_policy resource separately; variable retained for reference/tfvars
}

resource "azurerm_mssql_firewall_rule" "rules" {
  for_each = var.firewall_rules

  name             = each.key
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = each.value.start_ip_address
  end_ip_address   = each.value.end_ip_address
}

resource "azurerm_mssql_database" "databases" {
  for_each = var.databases

  name           = each.key
  server_id      = azurerm_mssql_server.main.id
  collation      = each.value.collation
  license_type   = each.value.license_type
  max_size_gb    = each.value.max_size_gb
  sku_name       = each.value.sku_name
  zone_redundant = each.value.zone_redundant
  tags           = var.tags

  dynamic "short_term_retention_policy" {
    for_each = try(each.value.short_term_retention_days, null) != null ? [1] : []
    content {
      retention_days = each.value.short_term_retention_days
    }
  }
}
