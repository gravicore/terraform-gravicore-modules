output "key_vault_id" {
  value = concat(azurerm_key_vault.default.*.id, [""])[0]
}

# Key outputs

output "vm_key_id" {
  value = concat(azurerm_key_vault_key.vm_key.*.id, [""])[0]
}

output "sa_key_id" {
  value = concat(azurerm_key_vault_key.sa_key.*.id, [""])[0]
}

# Certificate outputs

# Secret outputs
