output "sql_server_id" {
  value = azurerm_mssql_server.this.id
}

output "sql_server_fqdn" {
  value = azurerm_mssql_server.this.fully_qualified_domain_name
}

output "sql_database_id" {
  value = azurerm_mssql_database.this.id
}

output "sql_database_name" {
  value = azurerm_mssql_database.this.name
}

output "sql_server_identity_principal_id" {
  value = azurerm_mssql_server.this.identity[0].principal_id
}
