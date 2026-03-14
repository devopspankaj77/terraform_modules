output "id" {
  value = azurerm_mysql_flexible_server.main.id
}

output "fqdn" {
  value = azurerm_mysql_flexible_server.main.fqdn
}

output "database_ids" {
  value = { for k, d in azurerm_mysql_flexible_database.databases : k => d.id }
}
