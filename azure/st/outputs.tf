output "storage_account_ids" {
  value       = { for k, v in azurerm_storage_account.default : k => v.id }
  description = "The IDs of the Storage Accounts"
}

output "private_endpoint_fqdn" {
  value       = { for k, v in module.private_endpoint : k => v.private_endpoint_fqdn }
  description = "The FQDN of the Private Endpoints"
}

