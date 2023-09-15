output "resource_group_name" {
  description = "The name of the Resource Group"
  value       = concat(azurerm_resource_group.default.*.name, [])[0]
}

output "resource_group_id" {
  description = "The ID of the Resource Group."
  value       = concat(azurerm_resource_group.default.*.id, [])[0]
}

output "state_storage_account_name" {
  description = "The name of the Storage Account used for storing Terraform state."
  value       = concat(azurerm_storage_account.tfstate.*.name, [])[0]
}

output "state_storage_account_id" {
  description = "The ID of the Storage Account used for storing Terraform state."
  value       = concat(azurerm_storage_account.tfstate.*.id, [])[0]
}
