locals {
  private_endpoint_list = flatten([
    for k, st in var.storage_accounts : [
      for sc in st.network_rules.private_endpoints != null ? st.network_rules.private_endpoints : [] : {
        "${st.prefix}-${sc.subresource_name}" = {
          account_name         = st.prefix
          subnet_id            = sc.private_endpoint_subnet_id
          private_dns_zone_ids = sc.private_dns_zone_ids
          subresource_name     = sc.subresource_name
          st_key               = k
        }
      }
    ]
  ])

  private_endpoint_map = merge(local.private_endpoint_list...)
}

module "private_endpoint" {
  for_each = local.private_endpoint_map

  source     = "git::https://github.com/gravicore/terraform-gravicore-modules.git//azure/pep?ref=GDEV-336-release-azure"
  depends_on = [azurerm_storage_account.default]

  az_region            = var.az_region
  resource_group_name  = var.resource_group_name
  target_resource      = azurerm_storage_account.default[each.value.st_key].id
  subnet_id            = each.value.subnet_id
  private_dns_zone_ids = each.value.private_dns_zone_ids
  subresource_name     = each.value.subresource_name
  namespace            = var.namespace
  environment          = var.environment
  stage                = var.stage
  application          = var.application
}


resource "azurerm_storage_account_network_rules" "default" {
  depends_on                 = [module.private_endpoint]
  for_each                   = var.storage_accounts
  default_action             = each.value.network_rules != null ? each.value.network_rules.default_action : null
  storage_account_id         = azurerm_storage_account.default[each.key].id
  bypass                     = each.value.network_rules != null ? each.value.network_rules.bypass : null
  ip_rules                   = each.value.network_rules != null ? each.value.network_rules.ip_rules : null
  virtual_network_subnet_ids = each.value.network_rules != null ? each.value.network_rules.access_allowed_subnet_ids : null

  dynamic "timeouts" {
    for_each = each.value.network_rules != null && each.value.network_rules.timeouts != null ? [each.value.network_rules.timeouts] : []
    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

