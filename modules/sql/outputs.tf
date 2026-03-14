output "sql_server_id" {
  description = "ID of the SQL server"
  value       = azurerm_mssql_server.main.id
}

output "sql_server_fqdn" {
  description = "Fully qualified domain name of the SQL server"
  value       = azurerm_mssql_server.main.fully_qualified_domain_name
}

output "database_ids" {
  description = "Map of database names to IDs"
  value       = { for k, d in azurerm_mssql_database.databases : k => d.id }
}
