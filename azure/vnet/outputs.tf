output "private_subnet_ids" {
  value = values(azurerm_subnet.private)[*].id
}

output "public_subnet_ids" {
  value = values(azurerm_subnet.public)[*].id
}
