# ----------------------------------------------------------------------------------------------------------------------
# CAF resource
# ----------------------------------------------------------------------------------------------------------------------

module "azure_region" {
  source       = "claranet/regions/azurerm"
  version      = "6.1.0"
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
    for_each = var.policy_settings
    content {
      enabled                          = policy_settings.value.enabled
      mode                             = policy_settings.value.mode
      file_upload_limit_in_mb          = policy_settings.value.file_upload_limit_in_mb
      request_body_check               = policy_settings.value.request_body_check
      max_request_body_size_in_kb      = policy_settings.value.max_request_body_size_in_kb
      request_body_inspect_limit_in_kb = policy_settings.value.request_body_inspect_limit_in_kb

      dynamic "log_scrubbing" {
        for_each = policy_settings.value.log_scrubbing
        content {
          enabled = log_scrubbing.value.enabled

          dynamic "scrubbing_rule" {
            for_each = log_scrubbing.value.scrubbing_rule
            content {
              enabled                 = scrubbing_rule.value.enabled
              match_variable          = scrubbing_rule.value.match_variable
              selector_match_operator = scrubbing_rule.value.selector_match_operator
              selector                = scrubbing_rule.value.selector
            }
          }
        }
      }
    }
  }

  dynamic "managed_rules" {
    for_each = var.managed_rules
    content {
      dynamic "exclusion" {
        for_each = managed_rules.value.exclusion
        content {
          match_variable          = exclusion.value.match_variable
          selector                = exclusion.value.selector
          selector_match_operator = exclusion.value.selector_match_operator
          dynamic "excluded_rule_set" {
            for_each = exclusions.value.excluded_rule_set
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
        for_each = managed_rules.value.managed_rule_set
        content {
          type    = managed_rule_set.value.type
          version = managed_rule_set.value.version

          dynamic "rule_group_override" {
            for_each = managed_rule_set.value.rule_group_override
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

