output "private_dns_zone_ids" {
  description = "Map of Private DNS Zone IDs."
  value       = { for key, resource in azurerm_private_dns_zone.default : key => resource.id }
}

