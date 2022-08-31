output "storage_account_name" {
  description = "The name of the Storage Account"
  value       = concat(azurerm_storage_account.default.*.name, [""])[0]
}

output "storage_account_kind" {
  description = "The kind of the Storage Account"
  value       = concat(azurerm_storage_account.default.*.account_kind, [""])[0]
}

output "storage_account_type" {
  description = "The tier of the Storage Account"
  value       = concat(azurerm_storage_account.default.*.account_tier, [""])[0]
}
