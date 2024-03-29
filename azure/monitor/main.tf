# ----------------------------------------------------------------------------------------------------------------------
# CAF resource
# ----------------------------------------------------------------------------------------------------------------------


module "azure_region" {
  source       = "git::https://github.com/gravicore/terraform-gravicore-modules.git//azure/regions?ref=0.46.0"
  azure_region = var.az_region
}


# ----------------------------------------------------------------------------------------------------------------------
# Alerting
# ----------------------------------------------------------------------------------------------------------------------


resource "azurerm_monitor_action_group" "default" {
  for_each = var.create ? var.action_group : {}

  name                = join(var.delimiter, [local.stage_prefix, each.key, module.azure_region.location_short, "mag"])
  resource_group_name = var.resource_group_name
  short_name          = each.value.short_name
  enabled             = each.value.enabled
  location            = each.value.location

  dynamic "sms_receiver" {
    for_each = each.value.sms_receivers
    content {
      name         = sms_receiver.value.name
      country_code = sms_receiver.value.country_code
      phone_number = sms_receiver.value.phone_number
    }
  }

  dynamic "voice_receiver" {
    for_each = each.value.voice_receivers
    content {
      name         = voice_receiver.value.name
      country_code = voice_receiver.value.country_code
      phone_number = voice_receiver.value.phone_number
    }
  }

  dynamic "email_receiver" {
    for_each = each.value.email_receivers
    content {
      name                    = email_receiver.value.name
      email_address           = email_receiver.value.email_address
      use_common_alert_schema = email_receiver.value.use_common_alert_schema
    }
  }

  tags = local.tags
}

resource "azurerm_monitor_metric_alert" "default" {
  for_each = var.create ? var.metric_alerts : {}
  name     = join(var.delimiter, [local.stage_prefix, each.key, module.azure_region.location_short, "mma"])

  description = each.value.description

  resource_group_name = var.resource_group_name
  scopes              = each.value.scopes

  enabled       = each.value.enabled
  auto_mitigate = each.value.auto_mitigate
  severity      = each.value.severity

  frequency   = each.value.frequency
  window_size = each.value.window_size

  target_resource_type     = each.value.target_resource_type
  target_resource_location = each.value.target_resource_location

  dynamic "criteria" {
    for_each = each.value.criteria

    content {
      metric_namespace = criteria.value.metric_namespace
      metric_name      = criteria.value.metric_name

      aggregation = criteria.value.aggregation
      operator    = criteria.value.operator
      threshold   = criteria.value.threshold

      skip_metric_validation = criteria.value.skip_metric_validation

      dynamic "dimension" {
        for_each = { for d in criteria.value.dimension : d.name => d }
        content {
          name     = dimension.value.name
          operator = dimension.value.operator
          values   = dimension.value.values
        }
      }
    }
  }

  dynamic "dynamic_criteria" {
    for_each = each.value.dynamic_criteria
    content {
      metric_namespace = dynamic_criteria.value.metric_namespace
      metric_name      = dynamic_criteria.value.metric_name

      aggregation = dynamic_criteria.value.aggregation
      operator    = dynamic_criteria.value.operator

      alert_sensitivity        = dynamic_criteria.value.alert_sensitivity
      evaluation_total_count   = dynamic_criteria.value.evaluation_total_count
      evaluation_failure_count = dynamic_criteria.value.evaluation_failure_count
      ignore_data_before       = dynamic_criteria.value.ignore_data_before

      skip_metric_validation = dynamic_criteria.value.skip_metric_validation

      dynamic "dimension" {
        for_each = dynamic_criteria.value.dimension
        content {
          name     = dimension.value.name
          operator = dimension.value.operator
          values   = dimension.value.values
        }
      }
    }
  }

  dynamic "application_insights_web_test_location_availability_criteria" {
    for_each = toset(
      each.value.application_insights_web_test_location_availability_criteria != null
      ? ["enabled"] : []
    )

    content {
      web_test_id           = each.value.application_insights_web_test_location_availability_criteria.web_test_id
      component_id          = each.value.application_insights_web_test_location_availability_criteria.component_id
      failed_location_count = each.value.application_insights_web_test_location_availability_criteria.failed_location_count
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.default[each.value.action_group_key].id

    webhook_properties = {
      from = "terraform"
    }
  }

  tags = local.tags
}


resource "azurerm_monitor_activity_log_alert" "default" {
  for_each = var.create ? var.activity_log_alerts : {}

  name        = join(var.delimiter, [local.stage_prefix, each.key, module.azure_region.location_short, "ala"])
  description = each.value.description

  resource_group_name = var.resource_group_name
  scopes              = each.value.scopes

  criteria {
    operation_name = each.value.criteria.operation_name
    category       = each.value.criteria.category
    level          = each.value.criteria.level
    status         = each.value.criteria.status

    resource_provider = each.value.criteria.resource_provider
    resource_type     = each.value.criteria.resource_type
    resource_group    = each.value.criteria.resource_group
    resource_id       = each.value.criteria.resource_id

    dynamic "service_health" {
      for_each = each.value.service_health == null ? [] : ["enabled"]
      content {
        events    = service_health.events
        locations = service_health.locations
        services  = service_health.services
      }
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.default[each.value.action_group_key].id

    webhook_properties = {
      from = "terraform"
    }
  }

  tags = local.tags
}

