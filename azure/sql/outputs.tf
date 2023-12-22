output "mssql_server_id" {
  value = concat(azurerm_mssql_server.default.*.id, [""])[0]
}

output "mssql_server_name" {
  value = concat(azurerm_mssql_server.default.*.name, [""])[0]
}

