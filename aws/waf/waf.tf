variable scope {
  type        = string
  default     = "CLOUDFRONT"
  description = "(Required) Specifies whether this is for an AWS CloudFront distribution or for a regional application. Valid values are CLOUDFRONT or REGIONAL. To work with CloudFront, you must also specify the region us-east-1 (N. Virginia) on the AWS provider."
}
variable default_action {
  type        = string
  default     = "allow"
  description = "(Required) The action to perform if none of the rules contained in the WebACL match."
}

variable managed_rules {
  type        = list(any)
  default     = []
  description = "description"
}

variable custom_rules {
  type        = list(any)
  default     = []
  description = "description"
}

variable ip_set_rules {
  type        = list(any)
  default     = []
  description = "description"
}

variable visibility_config_cloudwatch_metrics_enabled {
  type        = bool
  default     = true
  description = "description"
}

variable visibility_config_sampled_requests_enabled {
  type        = bool
  default     = true
  description = "description"
}

variable visibility_config_metric_name {
  type        = string
  default     = null
  description = "description"
}

resource "aws_wafv2_web_acl" "waf_acl" {
  count       = var.create ? 1 : 0
  name        = local.module_prefix
  scope       = var.scope
  description = join(" ", list(var.desc_prefix, var.scope, "WAF"))
  tags        = local.tags

  default_action {
    dynamic "block" {
      for_each = var.default_action == "block" ? ["block"] : []
      content {}
    }
    dynamic "allow" {
      for_each = var.default_action == "allow" ? ["allow"] : []
      content {}
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = var.visibility_config_cloudwatch_metrics_enabled
    metric_name                = var.visibility_config_metric_name == null ? local.module_prefix : var.visibility_config_metric_name
    sampled_requests_enabled   = var.visibility_config_sampled_requests_enabled
  }

  dynamic "rule" {
    for_each = var.managed_rules
    content {
      name     = rule.value.name
      priority = rule.value.priority

      override_action {
        dynamic "count" {
          for_each = lookup(rule.value, "override_action", "none") == "count" ? ["count"] : []
          content {}
        }
        dynamic "none" {
          for_each = lookup(rule.value, "override_action", "none") == "none" ? ["none"] : []
          content {}
        }
      }

      statement {
        dynamic "managed_rule_group_statement" {
          for_each = [rule]
          content {
            name        = rule.value.name
            vendor_name = rule.value.vendor_name
            dynamic "excluded_rule" {
              for_each = lookup(rule.value, "excluded_rule", null) != null ? [rule] : []
              content {
                name = lookup(rule.value, "excluded_rule", null)
              }
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = lookup(rule.value, "cloudwatch_metrics_enabled", true)
        metric_name                = rule.value.name
        sampled_requests_enabled   = lookup(rule.value, "sampled_requests_enabled", true)
      }
    }
  }

  dynamic "rule" {
    for_each = var.ip_set_rules
    content {
      name     = join(var.delimiter, [local.module_prefix, rule.value.name, lookup(rule.value, "action", "count")])
      priority = rule.value.priority

      action {
        dynamic "allow" {
          for_each = lookup(rule.value, "action", "none") == "allow" ? ["allow"] : []
          content {}
        }
        dynamic "block" {
          for_each = lookup(rule.value, "action", "none") == "block" ? ["block"] : []
          content {}
        }
        dynamic "count" {
          for_each = lookup(rule.value, "action", "count") == "count" ? ["count"] : []
          content {}
        }
      }

      statement {
        dynamic "ip_set_reference_statement" {
          for_each = [rule]
          content {
            arn = aws_wafv2_ip_set.default[rule.key].arn
            dynamic "ip_set_forwarded_ip_config" {
              for_each = lookup(rule.value, "ip_set_forwarded_ip_config", null) == null ? [] : [rule]
              content {
                fallback_behavior = lookup(rule.value.ip_set_forwarded_ip_config, "fallback_behavior", null)
                header_name       = lookup(rule.value.ip_set_forwarded_ip_config, "header_name", null)
                position          = lookup(rule.value.ip_set_forwarded_ip_config, "position", null)
              }
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = lookup(rule.value, "cloudwatch_metrics_enabled", true)
        metric_name                = join(var.delimiter, [local.module_prefix, rule.value.name, lookup(rule.value, "action", "count")])
        sampled_requests_enabled   = lookup(rule.value, "sampled_requests_enabled", true)
      }
    }
  }
}

resource "aws_wafv2_ip_set" "default" {
  count = var.create && var.ip_set_rules != [] ? length(var.ip_set_rules) : 0
  name  = join(var.delimiter, [local.module_prefix, var.ip_set_rules[count.index].name])
  tags = local.tags

  scope              = lookup(var.ip_set_rules[count.index], "scope", "CLOUDFRONT")
  ip_address_version = lookup(var.ip_set_rules[count.index], "ip_address_version", "IPV4")
  addresses          = var.ip_set_rules[count.index].addresses
}


output waf_id {
  value       = aws_wafv2_web_acl.waf_acl[0].id
  description = "The ID of the WAF WebACL."
}

output waf_arn {
  value       = aws_wafv2_web_acl.waf_acl[0].arn
  description = "The ARN of the WAF WebACL"
}
