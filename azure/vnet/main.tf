locals {
  vpc_public_subnets = var.vpc_public_subnets != null ? coalescelist(var.vpc_public_subnets, compact([
    var.az_max_count >= 1 ? cidrsubnet(var.vnet_cidr_block[0], 6, 0) : "",
    var.az_max_count >= 2 ? cidrsubnet(var.vnet_cidr_block[0], 6, 1) : "",
    var.az_max_count >= 3 ? cidrsubnet(var.vnet_cidr_block[0], 6, 2) : "",
  ])) : []
  vpc_private_subnets = var.vpc_private_subnets != null ? coalescelist(var.vpc_private_subnets, compact([
    var.az_max_count >= 1 ? cidrsubnet(var.vnet_cidr_block[0], 4, 1) : "",
    var.az_max_count >= 2 ? cidrsubnet(var.vnet_cidr_block[0], 4, 2) : "",
    var.az_max_count >= 3 ? cidrsubnet(var.vnet_cidr_block[0], 4, 3) : "",
  ])) : []
  vpc_internal_subnets = var.vpc_internal_subnets != null ? coalescelist(var.vpc_internal_subnets, compact([
    var.az_max_count >= 1 ? cidrsubnet(var.vnet_cidr_block[0], 3, 1) : "",
    var.az_max_count >= 2 ? cidrsubnet(var.vnet_cidr_block[0], 3, 2) : "",
    var.az_max_count >= 3 ? cidrsubnet(var.vnet_cidr_block[0], 3, 3) : "",
  ])) : []
}

resource "azurerm_virtual_network" "default" {
  count               = var.create ? 1 : 0
  name                = join(var.delimiter, [local.stage_prefix, "vpc"])
  location            = var.az_location
  resource_group_name = var.resource_group_name
  tags                = local.tags

  bgp_community           = var.bgp_community == null ? null : join(":", ["12076", var.bgp_community])
  address_space           = var.vnet_cidr_block
  dns_servers             = var.dns_servers
  edge_zone               = var.edge_zone
  flow_timeout_in_minutes = var.flow_timeout_in_minutes
}

resource "azurerm_subnet" "public" {
  for_each             = var.create ? toset(local.vpc_public_subnets) : []
  name                 = join(var.delimiter, [local.module_prefix, "public", index(local.vpc_public_subnets, each.key) + 1])
  resource_group_name  = var.resource_group_name
  virtual_network_name = concat(azurerm_virtual_network.default.*.name, [""])[0]
  address_prefixes     = [each.key]
}

resource "azurerm_subnet" "private" {
  for_each             = var.create ? toset(local.vpc_private_subnets) : []
  name                 = join(var.delimiter, [local.module_prefix, "private", index(local.vpc_private_subnets, each.key) + 1])
  resource_group_name  = var.resource_group_name
  virtual_network_name = concat(azurerm_virtual_network.default.*.name, [""])[0]
  address_prefixes     = [each.key]
}

resource "azurerm_subnet" "internal" {
  for_each             = var.create ? toset(local.vpc_internal_subnets) : []
  name                 = join(var.delimiter, [local.module_prefix, "intra", index(local.vpc_internal_subnets, each.key) + 1])
  resource_group_name  = var.resource_group_name
  virtual_network_name = concat(azurerm_virtual_network.default.*.name, [""])[0]
  address_prefixes     = [each.key]
}

# resource "azurerm_network_security_group" "block-public-access" {
#   count               = var.create ? 1 : 0
#   name                = join(var.delimiter, [local.stage_prefix, "nsg"])
#   location            = var.az_location
#   resource_group_name = var.resource_group_name
#   tags                = local.tags

#   security_rule {
#     name                         = "BlockPublicInbound"
#     priority                     = 100
#     direction                    = "Inbound"
#     access                       = "Deny"
#     protocol                     = "*"
#     source_port_range            = "*"
#     destination_port_range       = "*"
#     source_address_prefix        = "*"
#     destination_address_prefixes = local.vpc_private_subnets
#   }
# }

# resource "azurerm_subnet_network_security_group_association" "default" {
#   for_each                  = var.create ? toset(local.vpc_private_subnets) : []
#   subnet_id                 = azurerm_subnet.private[each.key].id
#   network_security_group_id = concat(azurerm_network_security_group.block-public-access.*.id, [""])[0]
# }
