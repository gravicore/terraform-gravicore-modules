output "private_subnet_ids" {
  value = azurerm_subnet.private.*
}

output "public_subnet_ids" {
  value = azurerm_subnet.public.*
}
