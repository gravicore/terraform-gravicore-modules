output "container_registry_id" {
  value = concat(azurerm_container_registry.default[*].id, [""])[0]
}

output "private_endpoint_fqdn" {
  value = concat(module.pep[*].private_endpoint_fqdn, [""])[0]
}

