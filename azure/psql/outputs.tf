output "postgresql_flexible_server_id" {
  description = "The ID of the PostgreSQL Flexible Server."
  value       = concat(azurerm_postgresql_flexible_server.default.*.id, [""])[0]
}

output "postgresql_flexible_server_fqdn" {
  description = "The FQDN of the PostgreSQL Flexible Server."
  value       = concat(azurerm_postgresql_flexible_server.default.*.fqdn, [""])[0]
}

