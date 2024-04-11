# ----------------------------------------------------------------------------------------------------------------------
# CAF resource
# ----------------------------------------------------------------------------------------------------------------------


module "azure_region" {
  source       = "git::https://github.com/gravicore/terraform-gravicore-modules.git//azure/regions?ref=0.46.0"
  azure_region = var.az_region
}

# ----------------------------------------------------------------------------------------------------------------------
# Azure Front Door 
# ----------------------------------------------------------------------------------------------------------------------

resource "azurerm_cdn_frontdoor_profile" "default" {
  count               = var.create ? 1 : 0
  name                = local.module_prefix
  resource_group_name = var.resource_group_name
  sku_name            = var.sku_name

  response_timeout_seconds = var.response_timeout_seconds

  tags = local.tags
}

resource "azurerm_cdn_frontdoor_endpoint" "default" {
  for_each = var.create ? try({ for endpoint in var.endpoints : endpoint.name => endpoint }, {}) : {}

  name                     = each.value.name
  cdn_frontdoor_profile_id = one(azurerm_cdn_frontdoor_profile.default[*].id)

  enabled = each.value.enabled

  tags = local.tags
}

resource "azurerm_cdn_frontdoor_custom_domain" "default" {
  for_each = var.create ? try({ for custom_domain in var.custom_domains : custom_domain.name => custom_domain }, {}) : {}

  name                     = each.value.name
  cdn_frontdoor_profile_id = one(azurerm_cdn_frontdoor_profile.default[*].id)
  dns_zone_id              = each.value.dns_zone_id
  host_name                = each.value.host_name

  dynamic "tls" {
    for_each = each.value.tls == null ? [] : ["enabled"]
    content {
      certificate_type        = each.value.tls.certificate_type
      minimum_tls_version     = each.value.tls.minimum_tls_version
      cdn_frontdoor_secret_id = each.value.tls.cdn_frontdoor_secret_id
    }
  }
}

resource "azurerm_cdn_frontdoor_route" "default" {
  for_each = var.create ? try({ for route in var.routes : route.name => route }, {}) : {}

  name    = each.value.name
  enabled = each.value.enabled

  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.default[each.value.endpoint_name].id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.default[each.value.origin_group_name].id

  cdn_frontdoor_origin_ids = local.origins_names_per_route[each.value.name]

  forwarding_protocol = each.value.forwarding_protocol
  patterns_to_match   = each.value.patterns_to_match
  supported_protocols = each.value.supported_protocols

  dynamic "cache" {
    for_each = each.value.cache == null ? [] : ["enabled"]
    content {
      query_string_caching_behavior = each.value.cache.query_string_caching_behavior
      query_strings                 = each.value.cache.query_strings
      compression_enabled           = each.value.cache.compression_enabled
      content_types_to_compress     = each.value.cache.content_types_to_compress
    }
  }

  cdn_frontdoor_custom_domain_ids = try(local.custom_domains_per_route[each.key], [])
  cdn_frontdoor_origin_path       = each.value.origin_path
  cdn_frontdoor_rule_set_ids      = try(local.rule_sets_per_route[each.key], [])

  https_redirect_enabled = each.value.https_redirect_enabled
  link_to_default_domain = each.value.link_to_default_domain
}

resource "azurerm_cdn_frontdoor_origin_group" "default" {
  for_each = var.create ? try({ for origin_group in var.origin_groups : origin_group.name => origin_group }, {}) : {}

  name                     = each.value.name
  cdn_frontdoor_profile_id = one(azurerm_cdn_frontdoor_profile.default[*].id)

  session_affinity_enabled = each.value.session_affinity_enabled

  restore_traffic_time_to_healed_or_new_endpoint_in_minutes = each.value.restore_traffic_time_to_healed_or_new_endpoint_in_minutes

  dynamic "health_probe" {
    for_each = each.value.health_probe == null ? [] : ["enabled"]
    content {
      interval_in_seconds = each.value.health_probe.interval_in_seconds
      path                = each.value.health_probe.path
      protocol            = each.value.health_probe.protocol
      request_type        = each.value.health_probe.request_type
    }
  }

  load_balancing {
    additional_latency_in_milliseconds = each.value.load_balancing.additional_latency_in_milliseconds
    sample_size                        = each.value.load_balancing.sample_size
    successful_samples_required        = each.value.load_balancing.successful_samples_required
  }
}

resource "azurerm_cdn_frontdoor_origin" "default" {
  for_each = var.create ? try({ for origin in var.origins : origin.name => origin }, {}) : {}

  name                          = each.value.name
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.default[each.value.origin_group_name].id

  enabled                        = each.value.enabled
  certificate_name_check_enabled = each.value.certificate_name_check_enabled
  host_name                      = each.value.host_name
  http_port                      = each.value.http_port
  https_port                     = each.value.https_port
  origin_host_header             = each.value.origin_host_header
  priority                       = each.value.priority
  weight                         = each.value.weight

  dynamic "private_link" {
    for_each = each.value.private_link == null ? [] : ["enabled"]
    content {
      request_message        = each.value.private_link.request_message
      target_type            = each.value.private_link.target_type
      location               = each.value.private_link.location
      private_link_target_id = each.value.private_link.private_link_target_id
    }
  }
}

resource "null_resource" "approve_private_endpoints" {
  count = length(local.private_link_ids) > 0 ? 1 : 0
  depends_on = [
    azurerm_cdn_frontdoor_route.default
  ]
  provisioner "local-exec" {
    working_dir = path.module
    command     = "python approve_private_endpoints.py ${join(" ", local.private_link_ids)}"
  }
}

module "diagnostic" {
  count                 = var.create && var.logs_destinations_ids != [] ? 1 : 0
  source                = "git::https://github.com/gravicore/terraform-gravicore-modules.git//azure/diagnostic?ref=0.46.0"
  namespace             = var.namespace
  environment           = var.environment
  stage                 = var.stage
  application           = var.application
  az_region             = var.afd_region
  target_resource_id    = one(azurerm_cdn_frontdoor_profile.default[*].id)
  logs_destinations_ids = var.logs_destinations_ids
}

module "alerts" {
  count                 = var.create && (var.metric_alerts != null || var.activity_log_alerts != null) && var.action_group != null ? 1 : 0
  az_region             = var.az_region
  resource_group_name   = var.resource_group_name
  source                = "git::https://github.com/gravicore/terraform-gravicore-modules.git//azure/monitor?ref=GDEV-347-application-monitoring-with-workbooks-and-dashboards"
  namespace             = var.namespace
  environment           = var.environment
  stage                 = var.stage
  application           = var.application
  metric_alerts         = var.metric_alerts
  activity_log_alerts   = var.activity_log_alerts
  action_group          = var.action_group
  target_resource_ids   = [one(azurerm_cdn_frontdoor_profile.default[*].id)]
}

variable "az_region" {
  description = "Azure region"
  type        = string
}

variable "metric_alerts" {
  description = "List of metric alerts to create"
  type =  any
  default = null
}

variable "activity_log_alerts" {
  description = "List of activity log alerts to create"
  type =  any
  default = null
}

variable "action_group" {
  description = "Action group to use for alerts"
  type =  any
  default = null
}