output "sql_server_id" {
  value = concat(azurerm_mssql_server.default.*.id, [""])[0]
}

output "sql_server_FQDN" {
  value = concat(azurerm_mssql_server.default.*.fully_qualified_domain_name, [""])[0]
}

output "sql_database_id" {
  value = concat(azurerm_mssql_database.default.*.id)[0]
}

output "sql_database_name" {
  value = concat(azurerm_mssql_database.default.*.name)[0]
}
