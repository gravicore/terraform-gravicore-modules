# ----------------------------------------------------------------------------------------------------------------------
# Alerting
# ----------------------------------------------------------------------------------------------------------------------
data "azurerm_subscription" "current" {}

resource "azurerm_cost_anomaly_alert" "default" {
  count = var.create && var.azurerm_cost_anomaly_alert != null ? 1 : 0

  name            = var.azurerm_cost_anomaly_alert.name
  display_name    = var.azurerm_cost_anomaly_alert.display_name
  email_subject   = var.azurerm_cost_anomaly_alert.email_subject
  email_addresses = var.azurerm_cost_anomaly_alert.email_addresses
}

resource "azurerm_consumption_budget_subscription" "default" {
  for_each = var.create ? var.subscription_consumption_budget : {}

  name            = each.value.name
  subscription_id = each.value.subscription_id != null ? each.value.subscription_id : data.azurerm_subscription.current.id

  amount     = each.value.amount
  time_grain = each.value.time_grain

  time_period {
    start_date = each.value.time_period.start_date
    end_date   = each.value.time_period.end_date
  }

  dynamic "filter" {
    for_each = each.value.filter != null ? [each.value.filter] : []
    content {
      dynamic "dimension" {
        for_each = filter.value.dimension != null ? [filter.value.dimension] : []
        content {
          name     = dimension.value.name
          operator = dimension.value.operator
          values   = dimension.value.values
        }
      }

      dynamic "tag" {
        for_each = filter.value.tag != null ? [filter.value.tag] : []
        content {
          name     = tag.value.name
          operator = tag.value.operator
          values   = tag.value.values
        }
      }
    }
  }

  dynamic "notification" {
    for_each = each.value.notifications == null ? [] : each.value.notifications
    content {
      enabled        = notification.value.enabled
      threshold      = notification.value.threshold
      operator       = notification.value.operator
      threshold_type = notification.value.threshold_type
      contact_emails = notification.value.contact_emails
      contact_groups = notification.value.contact_groups
      contact_roles  = notification.value.contact_roles
    }
  }
}

data "azurerm_resource_group" "default" {
  for_each = var.create ? var.resource_group_consumption : {}
  name     = each.value.resource_group_id
}

resource "azurerm_consumption_budget_resource_group" "default" {
  for_each = var.create ? var.resource_group_consumption : {}

  name              = each.value.name
  resource_group_id = each.value.resource_group_id != null ? each.value.resource_group_id : data.azurerm_resource_group.default[each.key].id

  amount     = each.value.amount
  time_grain = each.value.time_grain

  time_period {
    start_date = each.value.time_period.start_date
    end_date   = each.value.time_period.end_date
  }

  dynamic "filter" {
    for_each = each.value.filter != null ? [each.value.filter] : []
    content {
      dynamic "dimension" {
        for_each = filter.value.dimension != null ? filter.value.dimension : []
        content {
          name     = dimension.value.name
          operator = dimension.value.operator
          values   = dimension.value.values
        }
      }

      dynamic "tag" {
        for_each = filter.value.tag != null ? filter.value.tag : []
        content {
          name     = tag.value.name
          operator = tag.value.operator
          values   = tag.value.values
        }
      }
    }
  }

  dynamic "notification" {
    for_each = each.value.notifications == null ? [] : each.value.notifications
    content {
      enabled        = notification.value.enabled
      threshold      = notification.value.threshold
      operator       = notification.value.operator
      threshold_type = notification.value.threshold_typ
      contact_emails = notification.value.contact_emails
      contact_groups = notification.value.contact_groups
      contact_roles  = notification.value.contact_roles
    }
  }
}

resource "azurerm_subscription_cost_management_view" "default" {
  for_each = var.create ? var.subscription_cost_management_view : {}

  name            = each.value.name
  display_name    = each.value.display_name
  chart_type      = each.value.chart_type
  accumulated     = each.value.accumulated
  subscription_id = each.value.subscription_id != null ? each.value.subscription_id : data.azurerm_subscription.current.id
  report_type     = each.value.report_type
  timeframe       = each.value.timeframe

  dynamic "dataset" {
    for_each = each.value.dataset != null ? [each.value.dataset] : []
    content {
      granularity = dataset.value.granularity

      dynamic "aggregation" {
        for_each = dataset.value.aggregation != null ? dataset.value.aggregation : []
        content {
          name        = aggregation.value.name
          column_name = aggregation.value.column_name
        }
      }

      dynamic "grouping" {
        for_each = dataset.value.grouping != null ? dataset.value.grouping : []
        content {
          name = grouping.value.name
          type = grouping.value.type
        }
      }

      dynamic "sorting" {
        for_each = dataset.value.sorting != null ? dataset.value.sorting : []
        content {
          direction = sorting.value.direction
          name      = sorting.value.name
        }
      }
    }
  }

  dynamic "kpi" {
    for_each = each.value.kpi != null ? each.value.kpi : []
    content {
      type = kpi.value.type
    }
  }

  dynamic "pivot" {
    for_each = each.value.pivot != null ? each.value.pivot : []
    content {
      name = pivot.value.name
      type = pivot.value.type
    }
  }
}


resource "azurerm_cost_management_scheduled_action" "default" {
  for_each = var.create ? var.cost_management_scheduled_action : {}

  name                 = each.value.name
  display_name         = each.value.display_name
  view_id              = azurerm_subscription_cost_management_view.default[each.value.view_identifier].id
  email_address_sender = each.value.email_address_sender
  email_subject        = each.value.email_subject
  email_addresses      = each.value.email_addresses
  message              = each.value.message
  frequency            = each.value.frequency
  start_date           = each.value.start_date
  end_date             = each.value.end_date

  day_of_month   = each.value.day_of_month
  days_of_week   = each.value.days_of_week
  hour_of_day    = each.value.hour_of_day
  weeks_of_month = each.value.weeks_of_month
}

