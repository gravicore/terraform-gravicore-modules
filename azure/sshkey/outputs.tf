output "public_key_datas" {
  value       = { for k, v in azurerm_key_vault_secret.publickey : k => v.value }
  description = "The Public Key Data of the ssh key pairs"
  sensitive   = true
}

