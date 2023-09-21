output "private_dns_zone_info" {
  description = "Map of Private DNS Zone names to their IDs."

  value = {
    for key, resource in azurerm_private_dns_zone.default : key => {
      name = resource.name
      id   = resource.id
    }
  }
}
