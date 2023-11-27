resource "azurerm_network_interface" "default" {
  count = var.new_network_interface != null ? 1 : 0

  location                      = var.location
  name                          = join("-", [local.module_prefix, "nic"])
  resource_group_name           = var.resource_group_name
  dns_servers                   = var.new_network_interface.dns_servers
  edge_zone                     = var.new_network_interface.edge_zone
  enable_accelerated_networking = var.new_network_interface.accelerated_networking_enabled
  enable_ip_forwarding          = var.new_network_interface.ip_forwarding_enabled
  internal_dns_name_label       = var.new_network_interface.internal_dns_name_label
  tags                          = merge(local.tags, local.default_vm_tags, var.extra_tags)

  dynamic "ip_configuration" {
    for_each = local.network_interface_ip_configuration_indexes

    content {
      name                                               = coalesce(var.new_network_interface.ip_configurations[ip_configuration.value].name, "${var.name}-nic${ip_configuration.value}")
      private_ip_address_allocation                      = var.new_network_interface.ip_configurations[ip_configuration.value].private_ip_address_allocation
      gateway_load_balancer_frontend_ip_configuration_id = var.new_network_interface.ip_configurations[ip_configuration.value].gateway_load_balancer_frontend_ip_configuration_id
      primary                                            = var.new_network_interface.ip_configurations[ip_configuration.value].primary
      private_ip_address                                 = var.new_network_interface.ip_configurations[ip_configuration.value].private_ip_address
      private_ip_address_version                         = var.new_network_interface.ip_configurations[ip_configuration.value].private_ip_address_version
      public_ip_address_id                               = var.new_network_interface.ip_configurations[ip_configuration.value].public_ip_address_id
      subnet_id                                          = var.subnet_id
    }
  }

  lifecycle {
    precondition {
      condition     = var.network_interface_ids == null
      error_message = "`new_network_interface` cannot be used along with `network_interface_ids`."
    }
  }
}

resource "azurerm_network_interface_security_group_association" "nic_nsg" {
  count = var.nic_nsg_id == null ? 0 : 1

  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = var.nic_nsg_id
}

resource "azurerm_network_interface_backend_address_pool_association" "lb_pool_association" {
  count = var.attach_load_balancer ? 1 : 0

  backend_address_pool_id = var.load_balancer_backend_pool_id
  ip_configuration_name   = local.ip_configuration_name
  network_interface_id    = azurerm_network_interface.nic.id
}

resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "appgw_pool_association" {
  count = var.attach_application_gateway ? 1 : 0

  backend_address_pool_id = var.application_gateway_backend_pool_id
  ip_configuration_name   = local.ip_configuration_name
  network_interface_id    = azurerm_network_interface.nic.id
}

