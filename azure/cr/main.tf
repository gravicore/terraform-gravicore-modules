# ----------------------------------------------------------------------------------------------------------------------
# CAF resource
# ----------------------------------------------------------------------------------------------------------------------

module "azure_region" {
  source       = "git::https://github.com/gravicore/terraform-gravicore-modules.git//azure/regions?ref=0.46.0"
  azure_region = var.az_region
}

# ----------------------------------------------------------------------------------------------------------------------
# Container registry
# ----------------------------------------------------------------------------------------------------------------------

resource "azurerm_container_registry" "default" {
  count = var.create ? 1 : 0
  name  = replace(local.module_prefix, "-", "")

  location            = var.az_region
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  admin_enabled       = var.admin_enabled

  public_network_access_enabled = var.public_network_access_enabled
  network_rule_bypass_option    = var.azure_services_bypass_allowed ? "AzureServices" : "None"

  data_endpoint_enabled = var.data_endpoint_enabled

  quarantine_policy_enabled = var.quarantine_policy_enabled
  export_policy_enabled     = var.export_policy_enabled
  zone_redundancy_enabled   = var.zone_redundancy_enabled
  anonymous_pull_enabled    = var.anonymous_pull_enabled

  dynamic "retention_policy" {
    for_each = var.images_retention_enabled && var.sku == "Premium" ? ["enabled"] : []

    content {
      enabled = var.images_retention_enabled
      days    = var.images_retention_days
    }
  }

  dynamic "trust_policy" {
    for_each = var.trust_policy_enabled && var.sku == "Premium" ? ["enabled"] : []

    content {
      enabled = var.trust_policy_enabled
    }
  }

  dynamic "georeplications" {
    for_each = var.georeplication_locations != null && var.sku == "Premium" ? var.georeplication_locations : []

    content {
      location                  = try(georeplications.value.location, georeplications.value)
      zone_redundancy_enabled   = try(georeplications.value.zone_redundancy_enabled, null)
      regional_endpoint_enabled = try(georeplications.value.regional_endpoint_enabled, null)
      tags                      = try(georeplications.value.tags, null)
    }
  }

  dynamic "network_rule_set" {
    for_each = length(concat(var.allowed_cidrs, var.allowed_subnets)) > 0 ? ["enabled"] : []

    content {
      default_action = "Deny"

      dynamic "ip_rule" {
        for_each = var.allowed_cidrs
        content {
          action   = "Allow"
          ip_range = ip_rule.value
        }
      }

      dynamic "virtual_network" {
        for_each = var.allowed_subnets
        content {
          action    = "Allow"
          subnet_id = virtual_network.value
        }
      }
    }
  }

  dynamic "identity" {
    for_each = var.identity_type != "" ? [var.identity_type] : []
    content {
      type         = identity.value
      identity_ids = var.user_assigned_identity_ids
    }
  }

  tags = local.tags

  lifecycle {
    precondition {
      condition     = ! var.data_endpoint_enabled || var.sku == "Premium"
      error_message = "Premium SKU is mandatory to enable the data endpoints."
    }
    precondition {
      condition     = var.sku == "Standard" || var.sku == "Premium" || var.anonymous_pull_enabled == false
      error_message = "anonymous_pull_enabled is only supported on resources with the Standard or Premium SKU."
    }
    precondition {
      condition     = var.export_policy_enabled || (! var.export_policy_enabled && ! var.public_network_access_enabled)
      error_message = "In order to set export_policy_enabled to false, make sure the public_network_access_enabled is also set to false."
    }
    precondition {
      condition = var.sku == "Premium" || (
        ! var.quarantine_policy_enabled &&
        ! var.export_policy_enabled &&
        ! var.zone_redundancy_enabled &&
        ! var.images_retention_enabled &&
      ! var.trust_policy_enabled)
      error_message = "quarantine_policy_enabled, retention_policy, trust_policy, export_policy_enabled, and zone_redundancy_enabled are only supported on resources with the Premium SKU."
    }
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# PEP Module
# ----------------------------------------------------------------------------------------------------------------------


module "private_endpoint" {
  depends_on           = [azurerm_container_registry.default]
  count                = var.create ? length(var.private_endpoints) : 0
  source               = "git::https://github.com/gravicore/terraform-gravicore-modules.git//azure/pep?ref=0.46.0"
  az_region            = var.az_region
  resource_group_name  = var.private_endpoints[count.index].resource_group_name
  target_resource      = one(azurerm_container_registry.default[*].id)
  subnet_id            = var.private_endpoints[count.index].subnet_id
  private_dns_zone_ids = var.private_endpoints[count.index].private_dns_zone_ids
  subresource_name     = var.private_endpoints[count.index].subresource_name
  namespace            = var.namespace
  environment          = var.environment
  stage                = var.stage
  application          = var.application
}

module "diagnostic" {
  count                 = var.create && var.logs_destinations_ids != [] ? 1 : 0
  source                = "git::https://github.com/gravicore/terraform-gravicore-modules.git//azure/diagnostic?ref=0.46.0"
  namespace             = var.namespace
  environment           = var.environment
  stage                 = var.stage
  application           = var.application
  az_region             = var.az_region
  target_resource_id    = concat(azurerm_container_registry.default[*].id, [""])[0]
  logs_destinations_ids = var.logs_destinations_ids
}

