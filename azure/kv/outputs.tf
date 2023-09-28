output "key_vault_id" {
  value = concat(azurerm_key_vault.default.*.id, [""])[0]
}

output "key_vault_url" {
  value = concat(azurerm_key_vault.default.*.vault_uri, [""])[0]
}

output "private_endpoint_id" {
  value = concat(module.private_endpoint.*.private_endpoint_id, [""])[0]
}

output "private_endpoint_fqdn" {
  value = concat(module.private_endpoint[*].private_endpoint_fqdn, [""])[0]
}

