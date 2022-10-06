# resource "azurerm_linux_virtual_machine" "default" {
#   name                = join(var.delimiter, [var.namespace, var.environment, var.stage, var.az_location, var.name, "vm", "boomi"])
#   resource_group_name = var.resource_group_name
#   location            = var.az_location

#   size           = "Standard_B2"
#   admin_username = "admin"
# }
