resource "azurerm_linux_virtual_machine" "default" {
  count                 = var.create ? 1 : 0
  name                  = join(var.delimiter, [var.namespace, var.environment, var.stage, var.az_location, var.name, "vm", "boomi"])
  resource_group_name   = var.resource_group_name
  location              = var.az_location
  tags                  = local.tags
  network_interface_ids = azurerm_network_interface.default.*.id

  size            = var.size
  admin_username  = var.admin_username
  admin_password  = var.admin_password
  license_type    = var.license_type

  os_disk {
    caching              = var.os_disk_caching
    storage_account_type = var.os_disk_account_type
  }

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
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
    name                                               = join(var.delimiter, [var.namespace, var.environment, var.stage, var.az_location, var.name, "vm", "ip-config"])
    subnet_id                                          = var.private_ip_address_version != "IPv4" ? null : var.subnet_id
    gateway_load_balancer_frontend_ip_configuration_id = var.gateway_load_balancer_frontend_ip_configuration_id
    private_ip_address_version                         = var.private_ip_address_version
    private_ip_address_allocation                      = var.private_ip_address_allocation
    private_ip_address                                 = var.private_ip_address_allocation == "static" ? null : var.private_ip_address
    public_ip_address_id                               = var.create_public_ip == null ? null : concat(azurerm_public_ip.default.*.id, [""])[0]
    primary                                            = var.primary
  }
}

resource "azurerm_public_ip" "default" {
  count               = var.create && var.create_public_ip ? 1 : 0
  name                = join(var.delimiter, [var.namespace, var.environment, var.stage, var.az_location, var.name, "vm", "public-ip"])
  resource_group_name = var.resource_group_name
  location            = var.az_location
  tags                = local.tags

  allocation_method       = var.allocation_method
  zones                   = var.zones
  domain_name_label       = var.domain_name_label
  edge_zone               = var.edge_zone
  idle_timeout_in_minutes = var.idle_timeout_in_minutes
  ip_tags                 = var.ip_tags
  ip_version              = var.ip_version
  reverse_fqdn            = var.reverse_fqdn
  sku                     = var.sku_tier == "Global" ? "Standard" : var.sku
  sku_tier                = var.sku_tier
}
