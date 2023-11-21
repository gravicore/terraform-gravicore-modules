# ----------------------------------------------------------------------------------------------------------------------
# CAF resource
# ----------------------------------------------------------------------------------------------------------------------


module "azure_region" {
  source       = "git::https://github.com/gravicore/terraform-gravicore-modules.git//azure/regions?ref=GDEV-336-release-azure"
  azure_region = var.az_region
}


# ----------------------------------------------------------------------------------------------------------------------
# SQL server resource
# ----------------------------------------------------------------------------------------------------------------------

resource "azurerm_mssql_server" "default" {
  count               = var.create ? 1 : 0
  name                = local.module_prefix
  resource_group_name = var.resource_group_name
  location            = var.var.az_region

  version                              = var.server_version
  connection_policy                    = var.connection_policy
  minimum_tls_version                  = var.tls_minimum_version
  public_network_access_enabled        = var.public_network_access_enabled
  outbound_network_restriction_enabled = var.outbound_network_restriction_enabled

  administrator_login          = var.administrator_login
  administrator_login_password = var.administrator_password

  dynamic "azuread_administrator" {
    for_each = var.azuread_administrator != null ? ["enabled"] : []
    content {
      login_username              = var.azuread_administrator.login_username
      object_id                   = var.azuread_administrator.object_id
      tenant_id                   = var.azuread_administrator.tenant_id
      azuread_authentication_only = var.azuread_administrator.azuread_authentication_only
    }
  }

  dynamic "identity" {
    for_each = var.identity != null ? ["enabled"] : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.type == "SystemAssigned" ? null : identity.value.identity_ids
    }
  }


  primary_user_assigned_identity_id = var.primary_user_assigned_identity_id

  tags = local.tags
}

resource "azurerm_mssql_firewall_rule" "default" {
  count = try(length(var.allowed_ip_addresses), 0)

  name      = var.allowed_ip_addresses[count.index]["rule_name"]
  server_id = azurerm_mssql_server.default[0].id

  start_ip_address = cidrhost(var.allowed_ip_addresses[count.index]["ip_prefix"], 0)
  end_ip_address   = cidrhost(var.allowed_ip_addresses[count.index]["ip_prefix"], -1)
}

resource "azurerm_mssql_elasticpool" "default" {
  count = var.elastic_pool_enabled ? 1 : 0

  name = join(var.delimiter, [local.stage_prefix, var.application, module.azure_region.location_short, "sqlep"])

  location            = var.az_region
  resource_group_name = var.resource_group_name

  license_type = var.elastic_pool_license_type

  server_name = azurerm_mssql_server.default[0].name

  per_database_settings {
    max_capacity = coalesce(var.elastic_pool_databases_max_capacity, var.elastic_pool_sku.capacity)
    min_capacity = var.elastic_pool_databases_min_capacity
  }

  max_size_gb                    = var.elastic_pool_max_size_gb
  max_size_bytes                 = var.elastic_pool_max_size_bytes
  zone_redundant                 = var.elastic_pool_zone_redundant
  maintenance_configuration_name = var.elastic_pool_maintenance_configuration_name

  sku {
    capacity = var.elastic_pool_sku.capacity
    name     = var.elastic_pool_sku.name
    tier     = var.elastic_pool_sku.tier
    family   = var.elastic_pool_sku.family
  }

  tags = local.tags
}

resource "azurerm_mssql_virtual_network_rule" "default" {
  for_each                             = try({ for subnet in local.allowed_subnets : subnet.name => subnet }, {})
  name                                 = each.key
  server_id                            = azurerm_mssql_server.default[0].id
  subnet_id                            = each.value.subnet_id
  ignore_missing_vnet_service_endpoint = var.ignore_missing_vnet_service_endpoint
}

resource "azurerm_mssql_server_security_alert_policy" "default" {
  for_each = toset(var.sql_server_security_alerting_enabled ? ["enabled"] : [])

  resource_group_name = var.resource_group_name
  server_name         = azurerm_mssql_server.default[0].name
  state               = "Enabled"
}

resource "azurerm_mssql_server_vulnerability_assessment" "default" {
  for_each = toset(var.sql_server_vulnerability_assessment_enabled ? ["enabled"] : [])

  server_security_alert_policy_id = azurerm_mssql_server_security_alert_policy.default["enabled"].id
  storage_container_path          = format("%s%s/", var.security_storage_account_blob_endpoint, var.security_storage_account_container_name)
  storage_account_access_key      = var.security_storage_account_access_key

  recurring_scans {
    enabled                   = true
    email_subscription_admins = true
    emails                    = var.alerting_email_addresses
  }
}

resource "azurerm_mssql_server_extended_auditing_policy" "default" {
  for_each = toset(var.sql_server_extended_auditing_enabled ? ["enabled"] : [])

  server_id                               = azurerm_mssql_server.default[0].id
  storage_endpoint                        = var.security_storage_account_blob_endpoint
  storage_account_access_key              = var.security_storage_account_access_key
  storage_account_access_key_is_secondary = false
  retention_in_days                       = var.sql_server_extended_auditing_retention_days
}

