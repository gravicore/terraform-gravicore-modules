resource "azurerm_linux_virtual_machine" "default" {
  count               = var.create ? 1 : 0
  name                = join(var.delimiter, [var.namespace, var.environment, var.stage, var.az_location, var.name, "vm", "boomi"])
  resource_group_name = var.resource_group_name
  location            = var.az_location
  tags                = local.tags

  size           = "Standard_B2"
  admin_username = "admin"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

resource "azurerm_network_interface" "default" {
  count               = var.create ? 1 : 0
  name                = join(var.delimiter, [var.namespace, var.environment, var.stage, var.az_location, var.name, "vm", "nic"])
  resource_group_name = var.resource_group_name
  location            = var.az_location
  tags                = local.tags

  dns_servers                   = var.dns_servers
  edge_zone                     = var.edge_zone
  enable_ip_forwarding          = var.enable_ip_forwarding
  enable_accelerated_networking = var.enable_accelerated_networking
  internal_dns_name_label       = var.internal_dns_name_label
  ip_configuration {
    name                                               = join(var.delimiter, [var.namespace, var.environment, var.stage, var.az_location, var.name, "vm", "ipconfig"])
    subnet_id                                          = var.private_ip_address_version != "IPv4" ? null : var.subnet_id
    gateway_load_balancer_frontend_ip_configuration_id = var.gateway_load_balancer_frontend_ip_configuration_id
    private_ip_address_version                         = var.private_ip_address_version
    private_ip_address_allocation                      = var.private_ip_address_allocation
    private_ip_address                                 = var.private_ip_address_allocation == "static" ? null : var.private_ip_address
    public_ip_address_id                               = var.public_ip_address_id
    primary                                            = var.primary
  }
}
