# ----------------------------------------------------------------------------------------------------------------------
# CAF resource
# ----------------------------------------------------------------------------------------------------------------------

module "azure_region" {
  source       = "claranet/regions/azurerm"
  version      = "6.1.0"
  azure_region = var.az_region
}

# ----------------------------------------------------------------------------------------------------------------------
# Admin credentials creation if AD authentication disabled
# ----------------------------------------------------------------------------------------------------------------------


resource "random_password" "default" {
  count            = var.create && var.create_mode == "Default" && var.authentication.password_auth_enabled ? 1 : 0
  length           = 32
  special          = true
  override_special = "_%@"
}

resource "azurerm_key_vault_secret" "postgresql_admin_password" {
  depends_on = [
    azurerm_postgresql_flexible_server.default,
    random_password.default,
  ]
  count        = var.create && var.create_mode == "Default" && var.authentication.password_auth_enabled ? 1 : 0
  name         = azurerm_postgresql_flexible_server.default.administrator_login
  value        = azurerm_postgresql_flexible_server.default.administrator_password
  key_vault_id = var.key_vault_id
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}


# ----------------------------------------------------------------------------------------------------------------------
# Postgresql Server resource
# ----------------------------------------------------------------------------------------------------------------------

resource "azurerm_postgresql_flexible_server" "default" {
  count = var.create ? 1 : 0

  resource_group_name = var.resource_group_name
  name                = local.module_prefix
  location            = var.az_region
  version             = var.postgresql_version
  sku_name            = join("_", [lookup(local.tier_map, var.tier, "GeneralPurpose"), "Standard", var.size])
  storage_mb          = var.storage_mb
  zone                = var.zone

  administrator_login    = var.create && var.create_mode == "Default" && var.authentication.password_auth_enabled ? var.administrator_login : null
  administrator_password = var.administrator_password != null ? var.administrator_password : (var.create && var.create_mode == "Default" && var.authentication.password_auth_enabled && var.administrator_password == null ? random_password.default[0].result : null)


  dynamic "high_availability" {
    for_each = var.standby_zone != null && var.tier != "Burstable" ? toset([var.standby_zone]) : toset([])

    content {
      mode                      = "ZoneRedundant"
      standby_availability_zone = high_availability.value
    }
  }

  dynamic "maintenance_window" {
    for_each = var.maintenance_window != null ? toset([var.maintenance_window]) : toset([])

    content {
      day_of_week  = lookup(maintenance_window.value, "day_of_week", 0)
      start_hour   = lookup(maintenance_window.value, "start_hour", 0)
      start_minute = lookup(maintenance_window.value, "start_minute", 0)
    }
  }

  dynamic "authentication" {
    for_each = var.authentication != null ? [var.authentication] : []

    content {
      active_directory_auth_enabled = lookup(authentication.value, "active_directory_auth_enabled", false)
      password_auth_enabled         = lookup(authentication.value, "password_auth_enabled", true)
      tenant_id                     = lookup(authentication.value, "tenant_id", null)
    }
  }

  dynamic "customer_managed_key" {
    for_each = var.customer_managed_key != null ? [var.customer_managed_key] : []

    content {
      key_vault_key_id                     = lookup(customer_managed_key.value, "key_vault_key_id", null)
      primary_user_assigned_identity_id    = lookup(customer_managed_key.value, "primary_user_assigned_identity_id", null)
      geo_backup_key_vault_key_id          = lookup(customer_managed_key.value, "geo_backup_key_vault_key_id", null)
      geo_backup_user_assigned_identity_id = lookup(customer_managed_key.value, "geogeo_backup_user_assigned_identity_id", null)
    }
  }

  dynamic "identity" {
    for_each = var.identity != null ? [var.identity] : []

    content {
      type         = lookup(identity.value, "type", null)
      identity_ids = lookup(identity.value, "identity_ids", null)
    }

  }

  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled
  create_mode                  = var.create_mode
  delegated_subnet_id          = var.delegated_subnet_id
  private_dns_zone_id          = var.private_dns_zone_id
  auto_grow_enabled            = var.auto_grow_enabled

  tags = local.tags

  lifecycle {
    precondition {
      condition     = var.private_dns_zone_id != null && var.delegated_subnet_id != null && var.allowed_ip_addresses == null || var.private_dns_zone_id == null && var.delegated_subnet_id == null && var.allowed_ip_addresses != null
      error_message = "var.private_dns_zone_id and var.delegated_subnet_id should either both be set or none of them."
    }
    ignore_changes = [
      tags,
      administrator_login,
      administrator_password,
      zone,
      high_availability.0.standby_availability_zone
    ]
  }
}


resource "azurerm_postgresql_flexible_server_configuration" "default" {
  count = length(var.flexible_server_configuration)

  name      = var.flexible_server_configuration[count.index].name
  server_id = azurerm_postgresql_flexible_server.default[0].id
  value     = var.flexible_server_configuration[count.index].value
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "default" {
  count = local.should_create_firewall_rule ? length(var.allowed_ip_addresses) : 0

  name             = join(var.delimiter, [replace(replace(element(var.allowed_ip_addresses, count.index), ".", "-"), "/", "-"), "psqlfw"])
  server_id        = azurerm_postgresql_flexible_server.default[0].id
  start_ip_address = cidrhost(var.allowed_ip_addresses[count.index], 0)
  end_ip_address   = cidrhost(var.allowed_ip_addresses[count.index], -1)
}

