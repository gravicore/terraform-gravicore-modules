output "vnet_details" {
  value = azurerm_virtual_network.default
}

output "subnet_details" {
  value = azurerm_subnet.default
}

output "subnet_nsg_details" {
  value = azurerm_network_security_group.default
}

output "subnet_nsg_association" {
  value = azurerm_subnet_network_security_group_association.default
}