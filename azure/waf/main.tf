# ----------------------------------------------------------------------------------------------------------------------
# CAF resource
# ----------------------------------------------------------------------------------------------------------------------

module "azure_region" {
  source       = "git::https://github.com/gravicore/terraform-gravicore-modules.git//azure/regions?ref=release-azure"
  azure_region = var.az_region
}

# ----------------------------------------------------------------------------------------------------------------------
# Application Gateway
# ----------------------------------------------------------------------------------------------------------------------

resource "azurerm_web_application_firewall_policy" "default" {
  count               = var.create ? 1 : 0
  location            = var.az_region
  resource_group_name = var.resource_group_name
  name                = local.module_prefix
  tags                = local.tags

  dynamic "custom_rules" {
    for_each = var.custom_rules
    content {
      enabled   = custom_rules.value.enabled
      name      = custom_rules.value.name
      priority  = custom_rules.value.priority
      rule_type = custom_rules.value.rule_type

      dynamic "match_conditions" {
        for_each = custom_rules.value.match_conditions
        content {
          dynamic "match_variables" {
            for_each = match_conditions.value.match_variables
            content {
              variable_name = match_variables.value.variable_name
              selector      = match_variables.value.selector
            }
          }

          operator           = match_conditions.value.operator
          negation_condition = match_conditions.value.negation_condition
          match_values       = match_conditions.value.match_values
          transforms         = match_conditions.value.transforms
        }
      }

      action               = custom_rules.value.action
      rate_limit_duration  = custom_rules.value.rate_limit_duration
      rate_limit_threshold = custom_rules.value.rate_limit_threshold
      group_rate_limit_by  = custom_rules.value.group_rate_limit_by
    }
  }

  dynamic "policy_settings" {
    for_each = var.policy_settings != null ? toset([var.policy_settings]) : toset([])
    content {
      enabled                          = var.policy_settings.enabled
      mode                             = var.policy_settings.mode
      file_upload_limit_in_mb          = var.policy_settings.file_upload_limit_in_mb
      request_body_check               = var.policy_settings.request_body_check
      max_request_body_size_in_kb      = var.policy_settings.max_request_body_size_in_kb
      request_body_inspect_limit_in_kb = var.policy_settings.request_body_inspect_limit_in_kb

      dynamic "log_scrubbing" {
        for_each = var.policy_settings.log_scrubbing != null ? ["enabled"] : []
        content {
          enabled = log_scrubbing.value.enabled

          dynamic "rule" {
            for_each = log_scrubbing.value.scrubbing_rule != null ? ["enabled"] : []
            content {
              enabled                 = rule.value.enabled
              match_variable          = rule.value.match_variable
              selector_match_operator = rule.value.selector_match_operator
              selector                = rule.value.selector
            }
          }
        }
      }
    }
  }

  dynamic "managed_rules" {
    for_each = var.managed_rules != null ? toset([var.managed_rules]) : toset([])
    content {
      dynamic "exclusion" {
        for_each = managed_rules.value.exclusion != null ? managed_rules.value.exclusion : []
        content {
          match_variable          = exclusion.value.match_variable
          selector                = exclusion.value.selector
          selector_match_operator = exclusion.value.selector_match_operator
          dynamic "excluded_rule_set" {
            for_each = exclusion.value.excluded_rule_set
            content {
              type    = excluded_rule_set.value.type
              version = excluded_rule_set.value.version

              dynamic "rule_group" {
                for_each = excluded_rule_set.value.rule_group
                content {
                  rule_group_name = rule_group.value.rule_group_name
                  excluded_rules  = rule_group.value.excluded_rules
                }
              }
            }
          }
        }
      }

      dynamic "managed_rule_set" {
        for_each = managed_rules.value.managed_rule_sets != null ? managed_rules.value.managed_rule_sets : []
        content {
          type    = managed_rule_set.value.type
          version = managed_rule_set.value.version

          dynamic "rule_group_override" {
            for_each = managed_rule_set.value.rule_group_override != null ? toset([managed_rule_set.value.rule_group_override]) : toset([])
            content {
              rule_group_name = rule_group_override.value.rule_group_name

              dynamic "rule" {
                for_each = rule_group_override.value.rule
                content {
                  id      = rule.value.id
                  enabled = rule.value.enabled
                  action  = rule.value.action
                }
              }
            }
          }
        }
      }
    }
  }
}

