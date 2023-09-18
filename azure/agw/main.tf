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


resource "azurerm_application_gateway" "default" {
  count               = var.create ? 1 : 0
  location            = var.az_region
  resource_group_name = var.resource_group_name
  name                = local.module_prefix
  zones               = var.zones
  firewall_policy_id  = var.firewall_policy_id
  enable_http2        = var.enable_http2
  tags                = local.tags
  sku {
    capacity = var.autoscaling_parameters != null ? null : var.sku_capacity
    name     = var.sku
    tier     = var.sku
  }

  frontend_ip_configuration {
    name                 = "public-ipc"
    public_ip_address_id = var.public_ip_address_id
  }

  dynamic "frontend_ip_configuration" {
    for_each = var.private ? ["enabled"] : []
    content {
      name                          = "private-ipc"
      private_ip_address_allocation = var.private ? "Static" : null
      private_ip_address            = var.private ? var.private_ip : null
      subnet_id                     = var.private ? var.subnet_id : null
    }
  }

  dynamic "frontend_port" {
    for_each = var.frontend_port_settings
    content {
      name = frontend_port.value.name
      port = frontend_port.value.port
    }
  }

  gateway_ip_configuration {
    name      = "gateway-ipc"
    subnet_id = var.subnet_id
  }

  force_firewall_policy_association = var.force_firewall_policy_association

  dynamic "waf_configuration" {
    for_each = var.sku == "WAF_v2" && var.waf_configuration != null ? [var.waf_configuration] : []
    content {
      enabled                  = waf_configuration.value.enabled
      file_upload_limit_mb     = waf_configuration.value.file_upload_limit_mb
      firewall_mode            = waf_configuration.value.firewall_mode
      max_request_body_size_kb = waf_configuration.value.max_request_body_size_kb
      request_body_check       = waf_configuration.value.request_body_check
      rule_set_type            = waf_configuration.value.rule_set_type
      rule_set_version         = waf_configuration.value.rule_set_version

      dynamic "disabled_rule_group" {
        for_each = waf_configuration.value.disabled_rule_group != null ? waf_configuration.value.disabled_rule_group : []
        content {
          rule_group_name = disabled_rule_group.value.rule_group_name
          rules           = disabled_rule_group.value.rules
        }
      }

      dynamic "exclusion" {
        for_each = waf_configuration.value.exclusion != null ? waf_configuration.value.exclusion : []
        content {
          match_variable          = exclusion.value.match_variable
          selector                = exclusion.value.selector
          selector_match_operator = exclusion.value.selector_match_operator
        }
      }
    }
  }

  dynamic "ssl_profile" {
    for_each = var.ssl_profile != null ? var.ssl_profile : []

    content {
      name                             = each.value.name
      trusted_client_certificate_names = var.ssl_profile.trusted_client_certificate_names
      verify_client_cert_issuer_dn     = var.ssl_profile.verify_client_cert_issuer_dn
      dynamic "ssl_policy" {
        for_each = ssl_profile.value.ssl_policy == null ? [] : ["enabled"]
        content {
          disabled_protocols   = ssl_profile.ssl_policy.disabled_protocols
          policy_type          = ssl_profile.ssl_policy.policy_type
          policy_name          = ssl_profile.ssl_policy.policy_type == "Predefined" ? ssl_profile.ssl_policy.policy_name : null
          cipher_suites        = ssl_profile.ssl_policy.policy_type == "Custom" ? ssl_profile.ssl_policy.cipher_suites : null
          min_protocol_version = ssl_profile.ssl_policy.policy_type == "Custom" ? ssl_profile.ssl_policy.min_protocol_version : null
        }
      }
    }
  }

  dynamic "backend_address_pool" {
    for_each = [for backend in var.backends : backend if backend.backend_pool != null]
    iterator = each_backend
    content {
      name         = join(var.delimiter, [each_backend.value.prefix, "backend-pool"])
      fqdns        = each_backend.value.backend_pool.fqdns
      ip_addresses = each_backend.value.backend_pool.ip_addresses
    }
  }

  dynamic "backend_http_settings" {
    for_each = [for backend in var.backends : backend if backend.backend_http_settings != null]
    iterator = each_backend

    content {
      name     = join(var.delimiter, [each_backend.value.prefix, "http-settings"])
      port     = each_backend.value.backend_http_settings.port
      protocol = each_backend.value.backend_http_settings.protocol

      cookie_based_affinity               = each_backend.value.backend_http_settings.cookie_based_affinity
      request_timeout                     = try(each_backend.value.backend_http_settings.request_timeout, null)
      host_name                           = try(each_backend.value.backend_http_settings.host_name, null)
      pick_host_name_from_backend_address = try(each_backend.value.backend_http_settings.pick_host_name_from_backend_address, null)
      path                                = try(each_backend.value.backend_http_settings.path, null)
      probe_name                          = each_backend.value.probes != null ? join(var.delimiter, [each_backend.value.prefix, "probe"]) : null

      dynamic "authentication_certificate" {
        for_each = each_backend.value.backend_http_settings.authentication_certificate != null ? list(each_backend.value.backend_http_settings.authentication_certificate) : []
        content {
          name = authentication_certificate.value.name
          id   = authentication_certificate.value.id
        }
      }

      dynamic "connection_draining" {
        for_each = each_backend.value.backend_http_settings.connection_draining != null ? list(each_backend.value.backend_http_settings.connection_draining) : []
        content {
          enabled           = connection_draining.value.enabled
          drain_timeout_sec = connection_draining.value.timeout
        }
      }
    }
  }

  dynamic "http_listener" {
    for_each = [for backend in var.backends : backend if backend.http_listeners != null]
    iterator = each_backend
    content {
      name                           = join(var.delimiter, [each_backend.value.prefix, "http-listener"])
      frontend_ip_configuration_name = var.private ? "pvt-ipc" : "public-ipc"
      frontend_port_name             = each_backend.value.http_listeners.frontend_port_name
      protocol                       = each_backend.value.http_listeners.protocol
      host_name                      = try(each_backend.value.http_listeners.host_name, null)
      host_names                     = try(each_backend.value.http_listeners.host_names, null)
      require_sni                    = try(each_backend.value.http_listeners.require_sni, null)
      ssl_certificate_name           = try(each_backend.value.http_listeners.ssl_certificate_name, null)

      dynamic "custom_error_configuration" {
        for_each = try(each_backend.value.http_listeners.custom_error_configurations != null ? each_backend.value.http_listeners.custom_error_configurations : [], [])
        content {
          status_code           = custom_error_configuration.value.status_code
          custom_error_page_url = custom_error_configuration.value.custom_error_page_url
        }
      }
    }
  }

  dynamic "redirect_configuration" {
    for_each = [for backend in var.backends : backend if backend.redirect_configuration != null]
    iterator = each_backend
    content {
      name                 = join("var.delimiter", [each_backend.value.prefix, "redirect"])
      redirect_type        = each_backend.value.redirect_configuration.redirect_type
      target_url           = try(each_backend.value.redirect_configuration.target_url, null)
      target_listener_name = try(each_backend.value.redirect_configuration.target_listener_name, null)
      include_path         = try(each_backend.value.redirect_configuration.include_path, false)
      include_query_string = try(each_backend.value.redirect_configuration.include_query_string, false)
    }
  }

  dynamic "rewrite_rule_set" {
    for_each = [for backend in var.backends : backend if backend.rewrite_rule_set != null]
    iterator = each_backend

    content {
      name = join(var.delimiter, [each_backend.value.prefix, "rewrite-rule-set"])

      dynamic "rewrite_rule" {
        for_each = each_backend.value.rewrite_rule_set.rewrite_rules != null ? each_backend.value.rewrite_rule_set.rewrite_rules : []
        iterator = rule
        content {
          name          = rule.value.name
          rule_sequence = rule.value.rule_sequence

          dynamic "condition" {
            for_each = rule.value.conditions != null ? rule.value.conditions : []
            iterator = cond
            content {
              variable    = cond.value.variable
              pattern     = cond.value.pattern
              ignore_case = cond.value.ignore_case
              negate      = cond.value.negate
            }
          }

          dynamic "response_header_configuration" {
            for_each = rule.value.response_header_configurations != null ? rule.value.response_header_configurations : []
            iterator = header
            content {
              header_name  = header.value.header_name
              header_value = header.value.header_value
            }
          }

          dynamic "request_header_configuration" {
            for_each = rule.value.request_header_configurations != null ? rule.value.request_header_configurations : []
            iterator = header
            content {
              header_name  = header.value.header_name
              header_value = header.value.header_value
            }
          }

          dynamic "url" {
            for_each = rule.value.url_reroute != null ? [rule.value.url_reroute] : []
            content {
              path         = rule.value.url_reroute.path
              query_string = rule.value.url_reroute.query_string
              components   = rule.value.url_reroute.components
              reroute      = rule.value.url_reroute.reroute
            }
          }
        }
      }
    }
  }


  dynamic "url_path_map" {
    for_each = [for backend in var.backends : backend if backend.url_path_map != null]
    iterator = each_backend
    content {
      name                                = try(join(var.delimiter, [each_backend.value.prefix, "url-path-map"]), null)
      default_backend_address_pool_name   = try(each_backend.value.url_path_map.use_redirect ? null : join(var.delimiter, [each_backend.value.prefix, "backend-pool"]), null)
      default_backend_http_settings_name  = try(each_backend.value.url_path_map.use_redirect ? null : join(var.delimiter, [each_backend.value.prefix, "http-settings"]), null)
      default_redirect_configuration_name = try(each_backend.value.url_path_map.use_redirect ? join(var.delimiter, [each_backend.value.prefix, "redirect"]) : null, null)
      default_rewrite_rule_set_name       = try(each_backend.value.url_path_map.default_rewrite_rule_set_name, null)

      dynamic "path_rule" {
        for_each = each_backend.value.url_path_map.path_rules != null ? each_backend.value.url_path_map.path_rules : []
        iterator = path_rules
        content {
          name                       = try(path_rules.value.name, null)
          backend_address_pool_name  = try(join(var.delimiter, [each_backend.value.prefix, "backend-pool"]), null)
          backend_http_settings_name = try(join(var.delimiter, [each_backend.value.prefix, "http-settings"]), null)
          rewrite_rule_set_name      = each_backend.value.rewrite_rule_set != null ? try(join(var.delimiter, [each_backend.value.prefix, "rewrite-rule-set"]), null) : null
          paths                      = try(path_rules.value.paths, null)
        }
      }
    }
  }

  dynamic "request_routing_rule" {
    for_each = [for backend in var.backends : backend if backend.request_routing_rule != null]
    iterator = each_backend

    content {
      name      = join(var.delimiter, [each_backend.value.prefix, "routing-rule"])
      rule_type = each_backend.value.request_routing_rule.rule_type

      http_listener_name          = join(var.delimiter, [each_backend.value.prefix, "http-listener"])
      backend_address_pool_name   = try(each_backend.value.request_routing_rule.use_redirect ? null : join(var.delimiter, [each_backend.value.prefix, "backend-pool"]), null)
      backend_http_settings_name  = try(each_backend.value.request_routing_rule.use_redirect ? null : join(var.delimiter, [each_backend.value.prefix, "http-settings"]), null)
      url_path_map_name           = try(join(var.delimiter, [each_backend.value.prefix, "url-path-map"]), null)
      redirect_configuration_name = try(each_backend.value.request_routing_rule.use_redirect ? join(var.delimiter, [each_backend.value.prefix, "redirect"]) : null, null)
      rewrite_rule_set_name       = each_backend.value.rewrite_rule_set != null ? try(join(var.delimiter, [each_backend.value.prefix, "rewrite-rule-set"]), null) : null
      priority                    = try(each_backend.value.request_routing_rule.priority, null)
    }
  }

  dynamic "probe" {
    for_each = [for backend in var.backends : backend if backend.probes != null]
    iterator = each_backend
    content {
      name                                      = each_backend.value.probes != null ? join(var.delimiter, [each_backend.value.prefix, "probe"]) : null
      interval                                  = each_backend.value.probes != null ? each_backend.value.probes.interval : null
      path                                      = each_backend.value.probes != null ? each_backend.value.probes.path : null
      protocol                                  = each_backend.value.probes != null ? each_backend.value.probes.protocol : null
      timeout                                   = each_backend.value.probes != null ? each_backend.value.probes.timeout : null
      unhealthy_threshold                       = each_backend.value.probes != null ? each_backend.value.probes.unhealthy_threshold : null
      host                                      = try(each_backend.value.probes != null && each_backend.value.probes.pick_host_name_from_backend_http_settings ? null : each_backend.value.probes.host, null)
      port                                      = try(each_backend.value.probes != null ? each_backend.value.probes.port : null, null)
      pick_host_name_from_backend_http_settings = try(each_backend.value.probes != null ? each_backend.value.probes.pick_host_name_from_backend_http_settings : null, null)
      minimum_servers                           = try(each_backend.value.probes != null ? each_backend.value.probes.minimum_servers : null, null)
      dynamic "match" {
        for_each = try(each_backend.value.probes != null ? [each_backend.value.probes.match] : [], [])
        content {
          body        = try(match.value.body, null)
          status_code = try(match.value.status_code, null)
        }
      }
    }
  }

  dynamic "identity" {
    for_each = var.user_assigned_identity_id != null ? ["enabled"] : []
    content {
      type         = "UserAssigned"
      identity_ids = [var.user_assigned_identity_id]
    }
  }

  dynamic "ssl_policy" {
    for_each = var.ssl_policy == null ? [] : ["enabled"]
    content {
      disabled_protocols   = var.ssl_policy.disabled_protocols
      policy_type          = var.ssl_policy.policy_type
      policy_name          = var.ssl_policy.policy_type == "Predefined" ? var.ssl_policy.policy_name : null
      cipher_suites        = var.ssl_policy.policy_type == "Custom" ? var.ssl_policy.cipher_suites : null
      min_protocol_version = var.ssl_policy.policy_type == "Custom" ? var.ssl_policy.min_protocol_version : null
    }
  }

  dynamic "authentication_certificate" {
    for_each = var.authentication_certificates_configs

    content {
      name = authentication_certificate.value.name
      data = authentication_certificate.value.data
    }
  }

  dynamic "trusted_client_certificate" {
    for_each = var.trusted_client_certificates_configs

    content {
      name = trusted_client_certificate.value.name
      data = trusted_client_certificate.value.data
    }
  }


  dynamic "autoscale_configuration" {
    for_each = var.autoscaling_parameters != null ? ["enabled"] : []
    content {
      min_capacity = var.autoscaling_parameters.min_capacity
      max_capacity = var.autoscaling_parameters.max_capacity
    }
  }

  dynamic "custom_error_configuration" {
    for_each = var.custom_error_configuration
    iterator = err_conf
    content {
      status_code           = err_conf.value.status_code
      custom_error_page_url = err_conf.value.custom_error_page_url
    }
  }

  dynamic "ssl_certificate" {
    for_each = var.ssl_certificates_configs
    iterator = ssl_crt
    content {
      name                = ssl_crt.value.name
      data                = ssl_crt.value.data
      password            = ssl_crt.value.password
      key_vault_secret_id = ssl_crt.value.key_vault_secret_id
    }
  }

  dynamic "trusted_root_certificate" {
    for_each = var.trusted_root_certificate_configs
    iterator = ssl_crt
    content {
      name                = ssl_crt.value.name
      data                = ssl_crt.value.data == null ? try(filebase64(ssl_crt.value.file_path), null) : ssl_crt.value.data
      key_vault_secret_id = ssl_crt.value.key_vault_secret_id
    }
  }

}

