output "postgresql_flexible_server_id" {
  description = "The ID of the PostgreSQL Flexible Server."
  value       = concat(azurerm_postgresql_flexible_server.default.*.id, [""])[0]

}

