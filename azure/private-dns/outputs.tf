output "private_dns_zone_ids" {
  description = "List of Private DNS Zone IDs."
  value       = azurerm_private_dns_zone.default[*].id
}

