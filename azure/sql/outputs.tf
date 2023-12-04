output "resource_group_id" {
  value = concat(azurerm_mssql_server.default.*.id, [""])[0]
}

output "resource_group_name" {
  value = concat(azurerm_mssql_server.default.*.name, [""])[0]
}

