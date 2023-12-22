locals {
  storage_containers_list = flatten([
    for k, st in var.storage_accounts : [
      for sc in st.storage_containers != null ? st.storage_containers : [] : {
        "${st.prefix}-${sc.name}" = {
          account_name          = st.prefix
          name                  = sc.name
          container_access_type = sc.container_access_type
          metadata              = sc.metadata
          timeouts              = sc.timeouts
          st_key                = k
        }
      }
    ]
  ])

  storage_containers_map = merge(local.storage_containers_list...)

  storage_share_list = flatten([
    for k, st in var.storage_accounts : [
      for ss in st.storage_share != null ? st.storage_share : [] : {
        "${st.prefix}-${ss.name}" = {
          account_name     = st.prefix
          name             = ss.name
          quota            = ss.quota
          access_tier      = ss.access_tier
          enabled_protocol = ss.enabled_protocol
          metadata         = ss.metadata
          acl              = ss.acl
          timeouts         = ss.timeouts
          st_key           = k
        }
      }
    ]
  ])

  storage_share_map = merge(local.storage_share_list...)
}


resource "azurerm_storage_container" "default" {
  for_each = local.storage_containers_map

  name                  = each.value.name
  storage_account_name  = azurerm_storage_account.default[each.value.st_key].name
  container_access_type = each.value.container_access_type
  metadata              = each.value.metadata

  dynamic "timeouts" {
    for_each = each.value.timeouts == null ? [] : [each.value.timeouts]
    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

resource "azurerm_storage_share" "default" {
  for_each = local.storage_share_map

  name                 = each.value.name
  quota                = each.value.quota
  storage_account_name = azurerm_storage_account.default[each.value.st_key].name
  access_tier          = each.value.access_tier
  enabled_protocol     = each.value.enabled_protocol
  metadata             = each.value.metadata

  dynamic "acl" {
    for_each = each.value.acl == null ? [] : each.value.acl
    content {
      id = acl.value.id

      dynamic "access_policy" {
        for_each = acl.value.access_policy == null ? [] : acl.value.access_policy
        content {
          permissions = access_policy.value.permissions
          expiry      = access_policy.value.expiry
          start       = access_policy.value.start
        }
      }
    }
  }

  dynamic "timeouts" {
    for_each = each.value.timeouts == null ? [] : [each.value.timeouts]
    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

