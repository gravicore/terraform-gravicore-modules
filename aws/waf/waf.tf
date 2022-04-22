# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

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
  description = <<EOF
  A rule statement used to run the rules that are defined in a managed rule group. A list of maps with the following syntax:

  managed_rules = [
    {
      name            = "AWSManagedRulesCommonRuleSet"    (string)                                            (Required) The name of the managed rule group
      vendor_name     = "AWS"                             (string)                                            (Required) The name of the managed rule group vendor
      priority        = 0                                 (number)                                            (Required) If you define more than one Rule in a WebACL, AWS WAF evaluates each request against the rules in order based on the value of priority. AWS WAF processes rules with lower priority first
      override_action = "none"                            (string, "none" or "count",     defaults to none)   (Optional) The override_action block supports the following arguments: count - Override the rule action setting to count (i.e., only count matches). none - Don't override the rule action setting
      excluded_rule {                                                                                         (Optional) The rules whose actions are set to COUNT by the web ACL, regardless of the action that is set on the rule
        name = "string"                                   (string,                        defaults to null)   (Required) The name of the rule to exclude. If the rule group is managed by AWS, see the documentation for a list of names in the appropriate rule group in use. https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups-list.html
      }
      cloudwatch_metrics_enabled = true                   (bool,   true or false,         defaults to true)   (Optional) A boolean indicating whether the associated resource sends metrics to CloudWatch
      sampled_requests_enabled   = true                   (bool,   true or false,         defaults to true)   (Optional) A boolean indicating whether AWS WAF should store a sampling of the web requests that match the rules
    }
  ]
EOF
}

variable ip_set_rules {
  type        = list(any)
  default     = []
  description = <<EOF
  A rule statement used to detect web requests coming from particular IP addresses or address ranges. A list of maps with the following syntax:

  ip_set_rules = [
    {
      name = "default-endpoints"                (string)
      priority = 0                              (number)                                                   (Required) If you define more than one Rule in a WebACL, AWS WAF evaluates each request against the rules in order based on the value of priority. AWS WAF processes rules with lower priority first
      action = "count"                          (string, "count", "allow" or "block", defaults to count)   (Optional) The action block supports the following arguments: allow - Instructs AWS WAF to allow the web request. block - Instructs AWS WAF to block the web request. count - Instructs AWS WAF to count the web request and allow it
      ip_address_version = "IPV4"               (string, "IPV4" or "IPV6",            defaults to count)   (Required) Specify IPV4 or IPV6
      addresses = ["0.0.0.0/0"]                 (list(string))                                             (Required) Contains an array of strings that specify one or more IP addresses or blocks of IP addresses in Classless Inter-Domain Routing (CIDR) notation. AWS WAF supports all address ranges for IP versions IPv4 and IPv6.
      ip_set_forwarded_ip_config = {                                                                       (Optional) The configuration for inspecting IP addresses in an HTTP header that you specify, instead of using the IP address that's reported by the web request origin
        fallback_behavior = "MATCH"             (string, "MATCH" or "NO_MATCH",       defaults to null)    (Optional) The match status to assign to the web request if the request doesn't have a valid IP address in the specified position
        header_name       = "Header"            (string,                              defaults to null)    (Optional) The name of the HTTP header to use for the IP address
        position          = "FIRST"             (string, "FIRST" or "LAST" or "ANY",  defaults to null)    (Optional) The position in the header to search for the IP address. If ANY is specified and the header contains more than 10 IP addresses, AWS WAFv2 inspects the last 10
      }
      cloudwatch_metrics_enabled = true         (bool,   true or false,               defaults to true)    (Optional) A boolean indicating whether the associated resource sends metrics to CloudWatch
      sampled_requests_enabled   = true         (bool,   true or false,               defaults to true)    (Optional) A boolean indicating whether AWS WAF should store a sampling of the web requests that match the rules
    }
  ]
EOF
}

variable geo_match_rules {
  type        = list(any)
  default     = []
  description = <<EOF
  A rule statement used to identify web requests based on country of origin. A list of maps with the following syntax:

  ip_set_rules = [
    {
      country_codes = ["RU","CN"]               (list(string))                                             (Required) An array of two-character country codes, for example, [ "US", "CN" ], from the alpha-2 country ISO codes of the ISO 3166 international standard. See the documentation for valid values. https://docs.aws.amazon.com/waf/latest/APIReference/API_GeoMatchStatement.html
      priority = 0                              (number)                                                   (Required) If you define more than one Rule in a WebACL, AWS WAF evaluates each request against the rules in order based on the value of priority. AWS WAF processes rules with lower priority first
      action = "count"                          (string, "count", "allow" or "block", defaults to count)   (Optional) The action block supports the following arguments: allow - Instructs AWS WAF to allow the web request. block - Instructs AWS WAF to block the web request. count - Instructs AWS WAF to count the web request and allow it
      forwarded_ip_config = {                                                                              (Optional) The configuration for inspecting IP addresses in an HTTP header that you specify, instead of using the IP address that's reported by the web request origin. Commonly, this is the X-Forwarded-For (XFF) header, but you can specify any header name. If the specified header isn't present in the request, AWS WAFv2 doesn't apply the rule to the web request at all. AWS WAFv2 only evaluates the first IP address found in the specified HTTP header
        fallback_behavior = "MATCH"             (string, "MATCH" or "NO_MATCH",       defaults to null)    (Optional) The match status to assign to the web request if the request doesn't have a valid IP address in the specified position
        header_name       = "Header"            (string,                              defaults to null)    (Optional) The name of the HTTP header to use for the IP address
      }
      cloudwatch_metrics_enabled = true         (bool,   true or false,               defaults to true)    (Optional) A boolean indicating whether the associated resource sends metrics to CloudWatch
      sampled_requests_enabled   = true         (bool,   true or false,               defaults to true)    (Optional) A boolean indicating whether AWS WAF should store a sampling of the web requests that match the rules
    }
  ]
EOF
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

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

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
          for_each = lookup(rule.value, "name", null) == null ? [] : [rule]
          content {
            name        = rule.value.name
            vendor_name = rule.value.vendor_name
            dynamic "excluded_rule" {
              for_each = lookup(rule.value, "excluded_rule", null) == null ? [] : [rule]
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
          for_each = lookup(rule.value, "name", null) == null ? [] : [rule]
          content {
            arn = aws_wafv2_ip_set.default[rule.key].arn
            dynamic "ip_set_forwarded_ip_config" {
              for_each = lookup(ip_set_reference_statement.value, "ip_set_forwarded_ip_config", null) == null ? [] : [ip_set_reference_statement]
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

  dynamic "rule" {
    for_each = var.geo_match_rules
    content {
      name     = join(var.delimiter, [local.module_prefix, "geo-match", lookup(rule.value, "action", "count")])
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
        dynamic "geo_match_statement" {
          for_each = lookup(rule.value, "country_codes", null) == null ? [] : [rule]
          content {
            country_codes = rule.value.country_codes
            dynamic "forwarded_ip_config" {
              for_each = lookup(geo_match_statement.value, "forwarded_ip_config", null) == null ? [] : [geo_match_statement]
              content {
                fallback_behavior = lookup(rule.value.forwarded_ip_config, "fallback_behavior", null)
                header_name       = lookup(rule.value.forwarded_ip_config, "header_name", null)
              }
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = lookup(rule.value, "cloudwatch_metrics_enabled", true)
        metric_name                = join(var.delimiter, [local.module_prefix, "geo-match", lookup(rule.value, "action", "count")])
        sampled_requests_enabled   = lookup(rule.value, "sampled_requests_enabled", true)
      }
    }
  }
}

resource "aws_wafv2_ip_set" "default" {
  count = var.create && var.ip_set_rules != [] ? length(var.ip_set_rules) : 0
  name  = join(var.delimiter, [local.module_prefix, var.ip_set_rules[count.index].name])
  tags  = local.tags

  scope              = var.scope
  ip_address_version = lookup(var.ip_set_rules[count.index], "ip_address_version", "IPV4")
  addresses          = var.ip_set_rules[count.index].addresses

  lifecycle {
    create_before_destroy = true
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output waf_id {
  value       = concat(aws_wafv2_web_acl.waf_acl.*.id, [""])[0]
  description = "The ID of the WAF WebACL."
}

output waf_arn {
  value       = concat(aws_wafv2_web_acl.waf_acl.*.arn, [""])[0]
  description = "The ARN of the WAF WebACL"
}
