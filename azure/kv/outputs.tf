output "vm-key-id" {
  value = concat(azurerm_key_vault_key.vm-key.*.id, [""])[0]
}