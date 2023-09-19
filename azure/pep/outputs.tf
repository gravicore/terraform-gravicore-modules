output "private_endpoint_id" {
  value = concat(azurerm_private_endpoint.default[*].id, [""])[0]
}

output "private_endpoint_fqdn" {
  value = concat(azurerm_private_endpoint.default[*].private_dns_zone_configs[0].record_sets[0].fqdn, [""])[0]
}
