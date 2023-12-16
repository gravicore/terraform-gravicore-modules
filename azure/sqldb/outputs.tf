output "mssql_database_ids" {
  value = { for db in azurerm_mssql_database.single_database : db.name => db.id }
}

output "mssql_database_names" {
  value = [for db in azurerm_mssql_database.single_database : db.name]
}

