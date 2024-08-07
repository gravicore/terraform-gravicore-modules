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

  name                = join(var.delimiter, [local.stage_prefix, var.application, each.key, module.azure_region.location_short, "mag"])
  resource_group_name = var.resource_group_name
  short_name          = each.value.short_name
  enabled             = each.value.enabled
  location            = each.value.location // it should be the each.value.location since location should be "global" by default

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
  for_each = var.create && var.metric_alerts != null && length(var.metric_alerts) > 0 ? var.metric_alerts : {}

  name = join(var.delimiter, [local.stage_prefix, var.application, each.key, module.azure_region.location_short, "mma"])

  description = each.value.description

  resource_group_name = var.resource_group_name

  scopes = length(var.target_resource_ids) > 0 ? var.target_resource_ids : length(each.value.scopes) > 0 ? each.value.scopes : null

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
    action_group_id = each.value.action_group_id == null ? azurerm_monitor_action_group.default[each.value.action_group_key].id : each.value.action_group_id

    webhook_properties = {
      from = "terraform"
    }
  }

  tags = local.tags
}


resource "azurerm_monitor_activity_log_alert" "default" {
  for_each = var.create && var.activity_log_alerts != null && length(var.activity_log_alerts) > 0 ? var.activity_log_alerts : {}

  name        = join(var.delimiter, [local.stage_prefix, var.application, each.key, module.azure_region.location_short, "ala"])
  description = each.value.description

  resource_group_name = var.resource_group_name
  scopes              = length(var.target_resource_ids) > 0 ? var.target_resource_ids : length(each.value.scopes) > 0 ? each.value.scopes : null

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
    action_group_id = each.value.action_group_id == null ? azurerm_monitor_action_group.default[each.value.action_group_key].id : each.value.action_group_id

    webhook_properties = {
      from = "terraform"
    }
  }

  tags = local.tags
}


resource "azurerm_portal_dashboard" "default" {
  for_each            = var.create ? var.portal_dashboards : {}
  name                = join(var.delimiter, [local.stage_prefix, var.application, each.key, module.azure_region.location_short, "dshbrd"])
  resource_group_name = var.resource_group_name
  location            = var.az_region
  tags                = local.tags
  dashboard_properties = templatefile("${each.value.file_path}", tomap(merge(each.value.file_vars, {
    "workbook_reference" = contains(keys(var.application_insights_workbooks), each.key) && contains(keys(each.value.file_vars), "workbook_uuid") ? var.application_insights_workbooks[each.key].uuid : null
  })))
}


resource "azurerm_application_insights_workbook" "default" {
  for_each            = var.create ? var.application_insights_workbooks : {}
  name                = each.value.uuid
  display_name        = join(var.delimiter, [local.stage_prefix, var.application, each.key, module.azure_region.location_short, "wrkbk"])
  resource_group_name = var.resource_group_name
  location            = var.az_region
  source_id           = each.value.source_id
  category            = each.value.category
  description         = each.value.description
  data_json           = templatefile("${each.value.file_path}", tomap(each.value.file_vars))
  tags                = local.tags
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "default" {
  for_each = var.create && var.scheduled_query_rules_alerts != null && length(var.scheduled_query_rules_alerts) > 0 ? var.scheduled_query_rules_alerts : {}

  name                              = join(var.delimiter, [local.stage_prefix, var.application, each.key, module.azure_region.location_short, "sqra"])
  resource_group_name               = var.resource_group_name
  location                          = each.value.scheduled_query_rules_alerts_region
  description                       = each.value.description
  enabled                           = each.value.enabled
  severity                          = each.value.severity
  evaluation_frequency              = each.value.evaluation_frequency
  window_duration                   = each.value.window_duration
  scopes                            = each.value.scopes
  auto_mitigation_enabled           = each.value.auto_mitigation_enabled
  workspace_alerts_storage_enabled  = each.value.workspace_alerts_storage_enabled
  display_name                      = each.value.display_name
  query_time_range_override         = each.value.query_time_range_override
  skip_query_validation             = each.value.skip_query_validation
  mute_actions_after_alert_duration = each.value.mute_actions_after_alert_duration
  target_resource_types             = each.value.target_resource_types

  dynamic "criteria" {
    for_each = each.value.criteria != null ? [each.value.criteria] : []
    content {
      query                   = criteria.value.query
      time_aggregation_method = criteria.value.time_aggregation_method
      threshold               = criteria.value.threshold
      operator                = criteria.value.operator
      resource_id_column      = criteria.value.resource_id_column
      metric_measure_column   = criteria.value.metric_measure_column

      dynamic "dimension" {
        for_each = criteria.value.dimension
        content {
          name     = dimension.value.name
          operator = dimension.value.operator
          values   = dimension.value.values
        }
      }

      dynamic "failing_periods" {
        for_each = criteria.value.failing_periods != null ? [criteria.value.failing_periods] : []
        content {
          minimum_failing_periods_to_trigger_alert = failing_periods.value.minimum_failing_periods_to_trigger_alert
          number_of_evaluation_periods             = failing_periods.value.number_of_evaluation_periods
        }
      }
    }
  }

  dynamic "action" {
    for_each = each.value.action != null ? [each.value.action] : []
    content {
      action_groups     = action.value.action_group_key != null ? ["${azurerm_monitor_action_group.default[action.value.action_group_key].id}"] : action.value.action_groups
      custom_properties = action.value.custom_properties
    }
  }

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  tags = local.tags
}

