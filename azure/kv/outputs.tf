output "key-vault-id" {
  value = concat(azurerm_key_vault.default.*.id, [""])[0]
}

output "tenant-id" {
  value = data.azurerm_client_config.current.tenant_id
}

# Key outputs

output "vm-key-id" {
  value = concat(azurerm_key_vault_key.vm-key.*.id, [""])[0]
}

output "sa-key-id" {
  value = concat(azurerm_key_vault_key.sa-key.*.id, [""])[0]
}

# Certificate outputs

# Secret outputs
