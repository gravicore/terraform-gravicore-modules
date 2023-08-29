output "vnet_details" {
  value = azurerm_virtual_network.vnet
}

output "subnet_details" {
  value = azurerm_subnet.subnet
}

output "subnet_nsg_details" {
  value = azurerm_network_security_group.subnet_nsg
}

output "subnet_nsg_association" {
  value = azurerm_subnet_network_security_group_association.subnet_nsg_association
}