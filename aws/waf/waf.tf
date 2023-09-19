# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "scope" {
  type        = string
  default     = "CLOUDFRONT"
  description = "(Required) Specifies whether this is for an AWS CloudFront distribution or for a regional application. Valid values are CLOUDFRONT or REGIONAL. To work with CloudFront, you must also specify the region us-east-1 (N. Virginia) on the AWS provider."
}
variable "default_action" {
  type        = string
  default     = "allow"
  description = "(Required) The action to perform if none of the rules contained in the WebACL match."
}

variable "managed_rule_group_statement" {
  type        = list(any)
  default     = []
  description = <<EOF
  A rule statement used to run the rules that are defined in a managed rule group. A list of maps with the following syntax:

  managed_rule_group_statement = [
    {
      name                       = "AWSManagedRulesCommonRuleSet"    (string)                                                       (Required) The name of the managed rule group
      vendor_name                = "AWS"                             (string)                                                       (Required) The name of the managed rule group vendor
      priority                   = 0                                 (number)                                                       (Required) If you define more than one Rule in a WebACL, AWS WAF evaluates each request against the rules in order based on the value of priority. AWS WAF processes rules with lower priority first
      override_action            = "none"                            (string, "none" or "count",                defaults to none)   (Optional) The override_action block supports the following arguments: count - Override the rule action setting to count (i.e., only count matches). none - Don't override the rule action setting
      excluded_rule              = "first_rule second_rule"          (string, list of space seperated values    defaults to null)   (Optional) The names of the rule to exclude whose actions are set to COUNT by the web ACL, regardless of the action that is set on the rule. If the rule group is managed by AWS, see the documentation for a list of names in the appropriate rule group in use. https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups-list.html
      cloudwatch_metrics_enabled = true                              (bool,   true or false,                    defaults to true)   (Optional) A boolean indicating whether the associated resource sends metrics to CloudWatch
      sampled_requests_enabled   = true                              (bool,   true or false,                    defaults to true)   (Optional) A boolean indicating whether AWS WAF should store a sampling of the web requests that match the rules
    }
  ]
EOF
}

variable "ip_set_reference_statement" {
  type        = list(any)
  default     = []
  description = <<EOF
  A rule statement used to detect web requests coming from particular IP addresses or address ranges. A list of maps with the following syntax:

  ip_set_reference_statement = [
    {
      name               = "default-endpoints"  (string)
      priority           = 0                    (number)                                                   (Required) If you define more than one Rule in a WebACL, AWS WAF evaluates each request against the rules in order based on the value of priority. AWS WAF processes rules with lower priority first
      action             = "count"              (string, "count", "allow" or "block", defaults to count)   (Optional) The action block supports the following arguments: allow - Instructs AWS WAF to allow the web request. block - Instructs AWS WAF to block the web request. count - Instructs AWS WAF to count the web request and allow it
      ip_address_version = "IPV4"               (string, "IPV4" or "IPV6",            defaults to count)   (Required) Specify IPV4 or IPV6
      addresses          = ["0.0.0.0/0"]        (list(string))                                             (Required) Contains an array of strings that specify one or more IP addresses or blocks of IP addresses in Classless Inter-Domain Routing (CIDR) notation. AWS WAF supports all address ranges for IP versions IPv4 and IPv6.
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

variable "geo_match_statement" {
  type        = list(any)
  default     = []
  description = <<EOF
  A rule statement used to identify web requests based on country of origin. A list of maps with the following syntax:

  geo_match_statement = [
    {
      country_codes = ["RU","CN"]               (list(string))                                             (Required) An array of two-character country codes, for example, [ "US", "CN" ], from the alpha-2 country ISO codes of the ISO 3166 international standard. See the documentation for valid values. https://docs.aws.amazon.com/waf/latest/APIReference/API_GeoMatchStatement.html
      priority      = 0                         (number)                                                   (Required) If you define more than one Rule in a WebACL, AWS WAF evaluates each request against the rules in order based on the value of priority. AWS WAF processes rules with lower priority first
      action        = "count"                   (string, "count", "allow" or "block", defaults to count)   (Optional) The action block supports the following arguments: allow - Instructs AWS WAF to allow the web request. block - Instructs AWS WAF to block the web request. count - Instructs AWS WAF to count the web request and allow it
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

variable "byte_match_statement" {
  type        = list(any)
  default     = []
  description = <<EOF
  A rule statement that defines a string match search for AWS WAF to apply to web requests. A list of maps with the following syntax:

  byte_match_statement = [
    {
      name                       = "default"        (string)
      priority                   = 0                (number)                                                                                                                    (Required) If you define more than one Rule in a WebACL, AWS WAF evaluates each request against the rules in order based on the value of priority. AWS WAF processes rules with lower priority first
      positional_constraint      = "STARTS_WITH"    (string, "EXACTLY", "STARTS_WITH", "ENDS_WITH", "CONTAINS" or "CONTAINS_WORD")                                              (Required) The area within the portion of a web request that you want AWS WAF to search for search_string. Valid values include the following: EXACTLY, STARTS_WITH, ENDS_WITH, CONTAINS, CONTAINS_WORD
      search_string              = "test"           (string)                                                                                                                    (Required) A string value that you want AWS WAF to search for. AWS WAF searches only in the part of web requests that you designate for inspection in field_to_match. The maximum length of the value is 50 bytes
      action                     = "count"          (string, "count", "allow" or "block", defaults to count)                                                                    (Optional) The action block supports the following arguments: allow - Instructs AWS WAF to allow the web request. block - Instructs AWS WAF to block the web request. count - Instructs AWS WAF to count the web request and allow it
      field_to_match             = "body"           (string, "all_query_arguments", "body", "method", "query_string", "single_header", "single_query_argument" or "uri_path")   (Optional) The part of a web request that you want AWS WAF to inspect. Only one of all_query_arguments, body, method, query_string, single_header, single_query_argument, or uri_path can be specified
      single_header_name         = "Referer"        (string)                                                                                                                    (Required if field_to_match = single_header) The name of the query header to inspect. This setting must be provided as lower case characters
      single_query_argument_name = "UserName"       (string)                                                                                                                    (Required if field_to_match = single_query_argument) The name of the query header to inspect. This setting must be provided as lower case characters
      text_transformation = [                                                                                                                                                   (Required) Text transformations eliminate some of the unusual formatting that attackers use in web requests in an effort to bypass detection
        {
        priority = 0                                (number)                                                                                                                    (Required) The relative processing order for multiple transformations that are defined for a rule statement. AWS WAF processes all transformations, from lowest priority to highest, before inspecting the transformed content.
        type     = "LOWERCASE"                      (string, "NONE", "COMPRESS_WHITE_SPACE", "HTML_ENTITY_DECODE", "LOWERCASE", "CMD_LINE" or "URL_DECODE")                     (Required) The transformation to apply, you can specify the following types: NONE, COMPRESS_WHITE_SPACE, HTML_ENTITY_DECODE, LOWERCASE, CMD_LINE, URL_DECODE
        }
      ]
    }
  ]
EOF
}

variable "rate_based_statement" {
  type        = list(any)
  default     = []
  description = <<EOF
  A rate-based rule tracks the rate of requests for each originating IP address, and triggers the rule action when the rate exceeds a limit that you specify on the number of requests in any 5-minute time span. This statement can not be nested. A list of maps with the following syntax:

  rate_based_statement = [
    {
      name               = "default"            (string)
      priority           = 0                    (number)                                                   (Required) If you define more than one Rule in a WebACL, AWS WAF evaluates each request against the rules in order based on the value of priority. AWS WAF processes rules with lower priority first
      limit              = 0                    (number)                                                   (Required) The limit on requests per 5-minute period for a single originating IP address
      aggregate_key_type = "IP"                 (string, "FORWARDED_IP" or "IP", defaults to IP)           (Optional) Setting that indicates how to aggregate the request counts. Valid values include: FORWARDED_IP or IP. Default: IP
      action             = "count"                          (string, "count", "allow" or "block", defaults to count)   (Optional) The action block supports the following arguments: allow - Instructs AWS WAF to allow the web request. block - Instructs AWS WAF to block the web request. count - Instructs AWS WAF to count the web request and allow it
      forwarded_ip_config = {                                                                              (Optional) The configuration for inspecting IP addresses in an HTTP header that you specify, instead of using the IP address that's reported by the web request origin. If aggregate_key_type is set to FORWARDED_IP, this block is required
        fallback_behavior = "MATCH"             (string, "MATCH" or "NO_MATCH",       defaults to null)    (Optional) The match status to assign to the web request if the request doesn't have a valid IP address in the specified position
        header_name       = "Header"            (string,                              defaults to null)    (Optional) The name of the HTTP header to use for the IP address
      }
    }
  ]
EOF
}

variable "regex_pattern_set_reference_statement" {
  type        = list(any)
  default     = []
  description = <<EOF
  A rule statement used to search web request components for matches with regular expressions. A list of maps with the following syntax:

  regex_pattern_set_reference_statement = [
    {
      name                       = "default"    (string)
      priority                   = 0            (number)                                                                                                                    (Required) If you define more than one Rule in a WebACL, AWS WAF evaluates each request against the rules in order based on the value of priority. AWS WAF processes rules with lower priority first
      action                     = "count"      (string, "count", "allow" or "block", defaults to count)                                                                    (Optional) The action block supports the following arguments: allow - Instructs AWS WAF to allow the web request. block - Instructs AWS WAF to block the web request. count - Instructs AWS WAF to count the web request and allow it
      arn                        = "<arn>"      (string)                                                                                                                    (Required) The Amazon Resource Name (ARN) of the Regex Pattern Set that this statement references.
      field_to_match             = "body"       (string, "all_query_arguments", "body", "method", "query_string", "single_header", "single_query_argument" or "uri_path")   (Optional) The part of a web request that you want AWS WAF to inspect. Only one of all_query_arguments, body, method, query_string, single_header, single_query_argument, or uri_path can be specified
      single_header_name         = "Referer"    (string)                                                                                                                    (Required if field_to_match = single_header) The name of the query header to inspect. This setting must be provided as lower case characters
      single_query_argument_name = "UserName"   (string)                                                                                                                    (Required if field_to_match = single_query_argument) The name of the query header to inspect. This setting must be provided as lower case characters
      text_transformation = [                                                                                                                                               (Required) Text transformations eliminate some of the unusual formatting that attackers use in web requests in an effort to bypass detection
        {
        priority = 0                            (number)                                                                                                                    (Required) The relative processing order for multiple transformations that are defined for a rule statement. AWS WAF processes all transformations, from lowest priority to highest, before inspecting the transformed content.
        type     = "LOWERCASE"                  (string, "NONE", "COMPRESS_WHITE_SPACE", "HTML_ENTITY_DECODE", "LOWERCASE", "CMD_LINE" or "URL_DECODE")                     (Required) The transformation to apply, you can specify the following types: NONE, COMPRESS_WHITE_SPACE, HTML_ENTITY_DECODE, LOWERCASE, CMD_LINE, URL_DECODE
        }
      ]
      cloudwatch_metrics_enabled = true         (bool,   true or false,               defaults to true)                                                                     (Optional) A boolean indicating whether the associated resource sends metrics to CloudWatch
      sampled_requests_enabled   = true         (bool,   true or false,               defaults to true)                                                                     (Optional) A boolean indicating whether AWS WAF should store a sampling of the web requests that match the rules
    }
  ]
EOF
}

variable "rule_group_reference_statement" {
  type        = list(any)
  default     = []
  description = <<EOF
  A rule statement used to run the rules that are defined in an WAFv2 Rule Group. A list of maps with the following syntax:

  rule_group_reference_statement = [
    {
      name                       = "default"                  (string)
      priority                   = 0                          (number)                                                       (Required) If you define more than one Rule in a WebACL, AWS WAF evaluates each request against the rules in order based on the value of priority. AWS WAF processes rules with lower priority first
      override_action            = "none"                     (string, "none" or "count",                defaults to none)   (Optional) The override_action block supports the following arguments: count - Override the rule action setting to count (i.e., only count matches). none - Don't override the rule action setting
      arn                        = "<arn>"                    (string)                                                       (Required) The Amazon Resource Name (ARN) of the aws_wafv2_rule_group resource.
      excluded_rule              = "first_rule second_rule"   (string, list of space seperated values    defaults to null)   (Optional) The names of the rule to exclude whose actions are set to COUNT by the web ACL, regardless of the action that is set on the rule. If the rule group is managed by AWS, see the documentation for a list of names in the appropriate rule group in use. https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups-list.html
      cloudwatch_metrics_enabled = true                       (bool,   true or false,               defaults to true)        (Optional) A boolean indicating whether the associated resource sends metrics to CloudWatch
      sampled_requests_enabled   = true                       (bool,   true or false,               defaults to true)        (Optional) A boolean indicating whether AWS WAF should store a sampling of the web requests that match the rules
    }
  ]
EOF
}

variable "size_constraint_statement" {
  type        = list(any)
  default     = []
  description = <<EOF
  A rule statement used to run the rules that are defined in an WAFv2 Rule Group. A list of maps with the following syntax:

  size_constraint_statement = [
    {
      name                       = "default"    (string)
      priority                   = 0            (number)                                                                                                                    (Required) If you define more than one Rule in a WebACL, AWS WAF evaluates each request against the rules in order based on the value of priority. AWS WAF processes rules with lower priority first
      action                     = "count"      (string, "count", "allow" or "block", defaults to count)                                                                    (Optional) The action block supports the following arguments: allow - Instructs AWS WAF to allow the web request. block - Instructs AWS WAF to block the web request. count - Instructs AWS WAF to count the web request and allow it
      comparison_operator        = "EQ"         (string, "EQ", "NE", "LE", "LT", "GE" or "GT")                                                                              (Required) The operator to use to compare the request part to the size setting
      size                       = 256          (number, between 0 and 21474836480)                                                                                         (Required) (Required) Size, in bytes, to compare to the request part, after any transformations
      field_to_match             = "body"       (string, "all_query_arguments", "body", "method", "query_string", "single_header", "single_query_argument" or "uri_path")   (Optional) The part of a web request that you want AWS WAF to inspect. Only one of all_query_arguments, body, method, query_string, single_header, single_query_argument, or uri_path can be specified
      single_header_name         = "Referer"    (string)                                                                                                                    (Required if field_to_match = single_header) The name of the query header to inspect. This setting must be provided as lower case characters
      single_query_argument_name = "UserName"   (string)                                                                                                                    (Required if field_to_match = single_query_argument) The name of the query header to inspect. This setting must be provided as lower case characters
      text_transformation = [                                                                                                                                               (Required) Text transformations eliminate some of the unusual formatting that attackers use in web requests in an effort to bypass detection
        {
        priority = 0                            (number)                                                                                                                    (Required) The relative processing order for multiple transformations that are defined for a rule statement. AWS WAF processes all transformations, from lowest priority to highest, before inspecting the transformed content.
        type     = "LOWERCASE"                  (string, "NONE", "COMPRESS_WHITE_SPACE", "HTML_ENTITY_DECODE", "LOWERCASE", "CMD_LINE" or "URL_DECODE")                     (Required) The transformation to apply, you can specify the following types: NONE, COMPRESS_WHITE_SPACE, HTML_ENTITY_DECODE, LOWERCASE, CMD_LINE, URL_DECODE
        }
      ]
      cloudwatch_metrics_enabled = true         (bool,   true or false,               defaults to true)                                                                     (Optional) A boolean indicating whether the associated resource sends metrics to CloudWatch
      sampled_requests_enabled   = true         (bool,   true or false,               defaults to true)                                                                     (Optional) A boolean indicating whether AWS WAF should store a sampling of the web requests that match the rules
    }
  ]
EOF
}

variable "visibility_config_cloudwatch_metrics_enabled" {
  type        = bool
  default     = true
  description = "description"
}

variable "visibility_config_sampled_requests_enabled" {
  type        = bool
  default     = true
  description = "description"
}

variable "visibility_config_metric_name" {
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
    for_each = var.managed_rule_group_statement
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
              for_each = lookup(rule.value, "excluded_rule", null) == null ? [] : toset(split(" ", rule.value.excluded_rule))
              content {
                name = excluded_rule.key
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
    for_each = var.ip_set_reference_statement
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
              for_each = lookup(rule.value, "ip_set_forwarded_ip_config", null) == null ? [] : [rule.value.ip_set_forwarded_ip_config]
              content {
                fallback_behavior = lookup(ip_set_forwarded_ip_config.value, "fallback_behavior", null)
                header_name       = lookup(ip_set_forwarded_ip_config.value, "header_name", null)
                position          = lookup(ip_set_forwarded_ip_config.value, "position", null)
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
    for_each = var.geo_match_statement
    content {
      name     = join(var.delimiter, [local.module_prefix, "geo-match", rule.value.priority, lookup(rule.value, "action", "count")])
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
              for_each = lookup(rule.value, "forwarded_ip_config", null) == null ? [] : [rule]
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
        metric_name                = join(var.delimiter, [local.module_prefix, "geo-match", rule.value.priority, lookup(rule.value, "action", "count")])
        sampled_requests_enabled   = lookup(rule.value, "sampled_requests_enabled", true)
      }
    }
  }

  dynamic "rule" {
    for_each = var.byte_match_statement
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
        dynamic "byte_match_statement" {
          for_each = lookup(rule.value, "search_string", null) == null ? [] : [rule]
          content {
            positional_constraint = rule.value.positional_constraint
            search_string         = rule.value.search_string
            dynamic "field_to_match" {
              for_each = lookup(rule.value, "field_to_match", null) == null ? [] : [rule]
              content {
                dynamic "all_query_arguments" {
                  for_each = lookup(rule.value, "field_to_match", null) == "all_query_arguments" ? ["field_to_match"] : []
                  content {}
                }
                dynamic "body" {
                  for_each = lookup(rule.value, "field_to_match", null) == "body" ? ["body"] : []
                  content {}
                }
                dynamic "method" {
                  for_each = lookup(rule.value, "field_to_match", null) == "method" ? ["method"] : []
                  content {}
                }
                dynamic "query_string" {
                  for_each = lookup(rule.value, "field_to_match", null) == "query_string" ? ["query_string"] : []
                  content {}
                }
                dynamic "single_header" {
                  for_each = lookup(rule.value, "field_to_match", null) == "single_header" ? ["single_header"] : []
                  content {
                    name = rule.value.single_header_name
                  }
                }
                dynamic "single_query_argument" {
                  for_each = lookup(rule.value, "field_to_match", null) == "single_query_argument" ? ["single_query_argument"] : []
                  content {
                    name = rule.value.single_query_argument_name
                  }
                }
                dynamic "uri_path" {
                  for_each = lookup(field_to_match.value, "uri_path", null) == "uri_path" ? ["uri_path"] : []
                  content {}
                }
              }
            }

            dynamic "text_transformation" {
              for_each = lookup(rule.value, "text_transformation", null) == null ? [] : rule.value.text_transformation

              content {
                priority = text_transformation.value.priority
                type     = text_transformation.value.type
              }
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = lookup(rule.value, "cloudwatch_metrics_enabled", true)
        metric_name                = join(var.delimiter, [local.module_prefix, "byte-match", rule.value.priority, lookup(rule.value, "action", "count")])
        sampled_requests_enabled   = lookup(rule.value, "sampled_requests_enabled", true)
      }
    }
  }

  dynamic "rule" {
    for_each = var.rate_based_statement
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
        dynamic "rate_based_statement" {
          for_each = lookup(rule.value, "limit", null) == null ? [rule] : []
          content {
            aggregate_key_type = lookup(rule.value, "aggregate_key_type", "IP")
            limit              = rule.value.limit
            dynamic "forwarded_ip_config" {
              for_each = lookup(rule.value, "forwarded_ip_config", null) == null ? [] : [rule]
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
        metric_name                = join(var.delimiter, [local.module_prefix, "rate-based", rule.value.priority, lookup(rule.value, "action", "count")])
        sampled_requests_enabled   = lookup(rule.value, "sampled_requests_enabled", true)
      }
    }
  }

  dynamic "rule" {
    for_each = var.regex_pattern_set_reference_statement
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
        dynamic "regex_pattern_set_reference_statement" {
          for_each = lookup(rule.value, "statement", null) == null ? [rule.value.statement] : []
          content {
            arn = rule.value.arn
            dynamic "field_to_match" {
              for_each = lookup(rule.value, "field_to_match", null) == null ? [] : [rule]
              content {
                dynamic "all_query_arguments" {
                  for_each = lookup(rule.value, "field_to_match", null) == "all_query_arguments" ? ["field_to_match"] : []
                  content {}
                }
                dynamic "body" {
                  for_each = lookup(rule.value, "field_to_match", null) == "body" ? ["body"] : []
                  content {}
                }
                dynamic "method" {
                  for_each = lookup(rule.value, "field_to_match", null) == "method" ? ["method"] : []
                  content {}
                }
                dynamic "query_string" {
                  for_each = lookup(rule.value, "field_to_match", null) == "query_string" ? ["query_string"] : []
                  content {}
                }
                dynamic "single_header" {
                  for_each = lookup(rule.value, "field_to_match", null) == "single_header" ? ["single_header"] : []
                  content {
                    name = rule.value.single_header_name
                  }
                }
                dynamic "single_query_argument" {
                  for_each = lookup(rule.value, "field_to_match", null) == "single_query_argument" ? ["single_query_argument"] : []
                  content {
                    name = rule.value.single_query_argument_name
                  }
                }
                dynamic "uri_path" {
                  for_each = lookup(field_to_match.value, "uri_path", null) == "uri_path" ? ["uri_path"] : []
                  content {}
                }
              }
            }

            dynamic "text_transformation" {
              for_each = lookup(rule.value, "text_transformation", null) == null ? [] : rule.value.text_transformation

              content {
                priority = text_transformation.value.priority
                type     = text_transformation.value.type
              }
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = lookup(rule.value, "cloudwatch_metrics_enabled", true)
        metric_name                = join(var.delimiter, [local.module_prefix, "regex-pattern", rule.value.priority, lookup(rule.value, "action", "count")])
        sampled_requests_enabled   = lookup(rule.value, "sampled_requests_enabled", true)
      }
    }
  }

  dynamic "rule" {
    for_each = var.rule_group_reference_statement
    content {
      name     = join(var.delimiter, [local.module_prefix, rule.value.name, lookup(rule.value, "action", "count")])
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
        dynamic "rule_group_reference_statement" {
          for_each = lookup(rule.value, "statement", null) == null ? [rule.value.statement] : []
          content {
            arn = rule.value.arn
            dynamic "excluded_rule" {
              for_each = lookup(rule.value, "excluded_rule", null) == null ? [] : toset(split(" ", rule.value.excluded_rule))
              content {
                name = excluded_rule.key
              }
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = lookup(rule.value, "cloudwatch_metrics_enabled", true)
        metric_name                = join(var.delimiter, [local.module_prefix, "rule-group", rule.value.priority, lookup(rule.value, "action", "count")])
        sampled_requests_enabled   = lookup(rule.value, "sampled_requests_enabled", true)
      }
    }
  }

  dynamic "rule" {
    for_each = var.size_constraint_statement
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
        dynamic "size_constraint_statement" {
          for_each = lookup(rule.value, "statement", null) == null ? [rule.value.statement] : []
          content {
            comparison_operator = rule.value.comparison_operator
            size                = rule.value.size
            dynamic "field_to_match" {
              for_each = lookup(rule.value, "field_to_match", null) == null ? [] : [rule]
              content {
                dynamic "all_query_arguments" {
                  for_each = lookup(rule.value, "field_to_match", null) == "all_query_arguments" ? ["field_to_match"] : []
                  content {}
                }
                dynamic "body" {
                  for_each = lookup(rule.value, "field_to_match", null) == "body" ? ["body"] : []
                  content {}
                }
                dynamic "method" {
                  for_each = lookup(rule.value, "field_to_match", null) == "method" ? ["method"] : []
                  content {}
                }
                dynamic "query_string" {
                  for_each = lookup(rule.value, "field_to_match", null) == "query_string" ? ["query_string"] : []
                  content {}
                }
                dynamic "single_header" {
                  for_each = lookup(rule.value, "field_to_match", null) == "single_header" ? ["single_header"] : []
                  content {
                    name = rule.value.single_header_name
                  }
                }
                dynamic "single_query_argument" {
                  for_each = lookup(rule.value, "field_to_match", null) == "single_query_argument" ? ["single_query_argument"] : []
                  content {
                    name = rule.value.single_query_argument_name
                  }
                }
                dynamic "uri_path" {
                  for_each = lookup(field_to_match.value, "uri_path", null) == "uri_path" ? ["uri_path"] : []
                  content {}
                }
              }
            }

            dynamic "text_transformation" {
              for_each = lookup(rule.value, "text_transformation", null) == null ? [] : rule.value.text_transformation

              content {
                priority = text_transformation.value.priority
                type     = text_transformation.value.type
              }
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = lookup(rule.value, "cloudwatch_metrics_enabled", true)
        metric_name                = join(var.delimiter, [local.module_prefix, "size-constraint", rule.value.priority, lookup(rule.value, "action", "count")])
        sampled_requests_enabled   = lookup(rule.value, "sampled_requests_enabled", true)
      }
    }
  }
}

resource "aws_wafv2_ip_set" "default" {
  count = var.create && var.ip_set_reference_statement != [] ? length(var.ip_set_reference_statement) : 0
  name  = join(var.delimiter, [local.module_prefix, var.ip_set_reference_statement[count.index].name])
  tags  = local.tags

  scope              = var.scope
  ip_address_version = lookup(var.ip_set_reference_statement[count.index], "ip_address_version", "IPV4")
  addresses          = var.ip_set_reference_statement[count.index].addresses

  lifecycle {
    create_before_destroy = true
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "waf_id" {
  value       = concat(aws_wafv2_web_acl.waf_acl.*.id, [""])[0]
  description = "The ID of the WAF WebACL."
}

output "waf_arn" {
  value       = concat(aws_wafv2_web_acl.waf_acl.*.arn, [""])[0]
  description = "The ARN of the WAF WebACL"
}
