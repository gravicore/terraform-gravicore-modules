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

