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
  count                             = var.create ? 1 : 0
  location                          = var.az_region
  resource_group_name               = var.resource_group_name
  name                              = local.module_prefix
  zones                             = var.zones
  force_firewall_policy_association = var.force_firewall_policy_association
  firewall_policy_id                = var.firewall_policy_id != null ? var.firewall_policy_id : null
  enable_http2                      = var.enable_http2
  tags                              = local.tags
  
  sku {
    name     = var.sku.name
    tier     = var.sku.tier
    capacity = var.autoscale_configuration == null ? var.sku.capacity : null
  }
  
  dynamic "frontend_ip_configuration" {
    for_each = var.private_ip_address != null ? [var.private_ip_address] : []
    content {
      name                          = "private-ipc"
      private_ip_address            = var.private_ip_address
      private_ip_address_allocation = "Static"
      subnet_id                     = var.subnet_id
    }
  }
  
  dynamic "frontend_ip_configuration" {
    for_each = var.public_ip_address_id != null ? [var.public_ip_address_id] : []
    content {
      name                 = "public-ipc"
      public_ip_address_id = var.public_ip_address_id
    }
  }

  dynamic "frontend_port" {
    for_each = var.frontend_port
    content {
      name = frontend_port.value.name
      port = frontend_port.value.port
    }
  }

  gateway_ip_configuration {
    name      = "gateway-ipc"
    subnet_id = var.subnet_id
  }

  dynamic "backend_address_pool" {
    for_each = var.backend_address_pools
    content {
      name         = backend_address_pool.value.name
      fqdns        = backend_address_pool.value.fqdns
      ip_addresses = backend_address_pool.value.ip_addresses
    }
  }

  dynamic "backend_http_settings" {
    for_each = var.backend_http_settings
    content {
      name                                = join(var.delimiter, [backend_http_settings.name, "http-settings"])
      cookie_based_affinity               = backend_http_settings.value.cookie_based_affinity
      affinity_cookie_name                = backend_http_settings.value.affinity_cookie_name
      path                                = backend_http_settings.value.path
      port                                = backend_http_settings.value.enable_https ? 443 : 80
      probe_name                          = backend_http_settings.value.probe_name
      protocol                            = backend_http_settings.value.enable_https ? "Https" : "Http"
      request_timeout                     = backend_http_settings.value.request_timeout
      host_name                           = backend_http_settings.value.pick_host_name_from_backend_address == false ? backend_http_settings.value.host_name : null
      pick_host_name_from_backend_address = backend_http_settings.value.pick_host_name_from_backend_address

      dynamic "authentication_certificate" {
        for_each = backend_http_settings.value.authentication_certificate[*]
        content {
          name = authentication_certificate.value.name
        }
      }

      trusted_root_certificate_names = backend_http_settings.value.trusted_root_certificate_names

      dynamic "connection_draining" {
        for_each = backend_http_settings.value.connection_draining[*]
        content {
          enabled           = connection_draining.value.enable_connection_draining
          drain_timeout_sec = connection_draining.value.drain_timeout_sec
        }
      }
    }
  }

  dynamic "http_listener" {
    for_each = var.http_listeners
    content {
      name                           = join(var.delimiter, [http_listener.value.name, "http-listener"])
      frontend_ip_configuration_name = var.public_listener ? "public-ipc" : "private-ipc"
      frontend_port_name             = http_listener.value.frontend_port_name
      host_name                      = http_listener.value.host_name
      host_names                     = http_listener.value.host_names
      protocol                       = http_listener.value.ssl_certificate_name == null ? "Http" : "Https"
      require_sni                    = http_listener.value.ssl_certificate_name != null ? http_listener.value.require_sni : null
      ssl_certificate_name           = http_listener.value.ssl_certificate_name
      firewall_policy_id             = http_listener.value.firewall_policy_id
      ssl_profile_name               = http_listener.value.ssl_profile_name

      dynamic "custom_error_configuration" {
        for_each = http_listener.value.custom_error_configuration != null ? lookup(http_listener.value, "custom_error_configuration", {}) : []
        content {
          custom_error_page_url = lookup(custom_error_configuration.value, "custom_error_page_url", null)
          status_code           = lookup(custom_error_configuration.value, "status_code", null)
        }
      }
    }
  }

  dynamic "redirect_configuration" {
    for_each = var.redirect_configuration
    content {
      name                 = redirect_configuration.value.name
      redirect_type        = redirect_configuration.value.redirect_type
      target_listener_name = redirect_configuration.value.target_listener_name
      target_url           = redirect_configuration.value.target_url
      include_path         = redirect_configuration.value.include_path
      include_query_string = redirect_configuration.value.include_query_string
    }
  }

  dynamic "rewrite_rule_set" {
    for_each = var.appgw_rewrite_rule_set
    content {
      name = join(var.delimiter, [rewrite_rule_set.value.name, "rewrite-rule-set"])

      dynamic "rewrite_rule" {
        for_each = rewrite_rule_set.value.rewrite_rules
        iterator = rule
        content {
          name          = rule.value.name
          rule_sequence = rule.value.rule_sequence

          dynamic "condition" {
            for_each = rule.value.conditions
            iterator = cond
            content {
              variable    = cond.value.variable
              pattern     = cond.value.pattern
              ignore_case = cond.value.ignore_case
              negate      = cond.value.negate
            }
          }

          dynamic "response_header_configuration" {
            for_each = rule.value.response_header_configurations
            iterator = header
            content {
              header_name  = header.value.header_name
              header_value = header.value.header_value
            }
          }

          dynamic "request_header_configuration" {
            for_each = rule.value.request_header_configurations
            iterator = header
            content {
              header_name  = header.value.header_name
              header_value = header.value.header_value
            }
          }

          dynamic "url" {
            for_each = rule.value.url_reroute != null ? ["enabled"] : []
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
    for_each = var.url_path_map
    content {
      name                                = url_path_map.value.name
      default_redirect_configuration_name = url_path_map.value.default_backend_address_pool_name == null && url_path_map.value.default_backend_http_settings_name == null ? url_path_map.value.default_redirect_configuration_name : null
      default_backend_address_pool_name   = url_path_map.value.default_redirect_configuration_name == null ? url_path_map.value.default_backend_address_pool_name : null
      default_backend_http_settings_name  = url_path_map.value.default_redirect_configuration_name == null ? coalesce(url_path_map.value.default_backend_http_settings_name, url_path_map.value.default_backend_address_pool_name) : null
      default_rewrite_rule_set_name       = url_path_map.value.default_rewrite_rule_set_name

      dynamic "path_rule" {
        for_each = url_path_map.value.path_rules
        content {
          name                        = path_rule.value.name
          backend_address_pool_name   = coalesce(path_rule.value.backend_address_pool_name, path_rule.value.name)
          backend_http_settings_name  = coalesce(path_rule.value.backend_http_settings_name, path_rule.value.name)
          rewrite_rule_set_name       = path_rule.value.rewrite_rule_set_name
          paths                       = path_rule.value.paths
          redirect_configuration_name = path_rule.value.redirect_configuration_name
          firewall_policy_id          = path_rule.value.firewall_policy_id
        }
      }
    }
  }

  dynamic "request_routing_rule" {
    for_each = var.request_routing_rule
    iterator = routing
    content {
      name      = routing.value.name
      rule_type = routing.value.rule_type

      http_listener_name          = coalesce(routing.value.http_listener_name, routing.value.name)
      backend_address_pool_name   = routing.value.backend_address_pool_name
      backend_http_settings_name  = routing.value.backend_http_settings_name
      url_path_map_name           = routing.value.url_path_map_name
      redirect_configuration_name = routing.value.redirect_configuration_name
      rewrite_rule_set_name       = routing.value.rewrite_rule_set_name
      priority                    = coalesce(routing.value.priority, routing.key + 1)
    }
  }

  dynamic "probe" {
    for_each = var.health_probes
    content {
      name = join(var.delimiter, [probe.value.name, "probe"])

      host     = probe.value.host
      port     = probe.value.port
      interval = probe.value.interval

      path     = probe.value.path
      protocol = probe.value.protocol
      timeout  = probe.value.timeout

      pick_host_name_from_backend_http_settings = probe.value.pick_host_name_from_backend_http_settings
      unhealthy_threshold                       = probe.value.unhealthy_threshold
      minimum_servers                           = probe.value.minimum_servers
      match {
        body        = probe.value.match.body
        status_code = probe.value.match.status_code
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
  
  dynamic "ssl_profile" {
    for_each = var.ssl_profile == null ? [] : ["enabled"]

    content {
      name                             = var.ssl_profile.name
      trusted_client_certificate_names = var.ssl_profile.trusted_client_certificate_names
      verify_client_cert_issuer_dn     = var.ssl_profile.verify_client_cert_issuer_dn
      dynamic "ssl_policy" {
        for_each = var.ssl_profile.ssl_policy == null ? [] : ["enabled"]
        content {
          disabled_protocols   = var.ssl_profile.ssl_policy.disabled_protocols
          policy_type          = var.ssl_profile.ssl_policy.policy_type
          policy_name          = var.ssl_profile.ssl_policy.policy_type == "Predefined" ? var.ssl_profile.ssl_policy.policy_name : null
          cipher_suites        = var.ssl_profile.ssl_policy.policy_type == "Custom" ? var.ssl_profile.ssl_policy.cipher_suites : null
          min_protocol_version = var.ssl_profile.ssl_policy.policy_type == "Custom" ? var.ssl_profile.ssl_policy.min_protocol_version : null
        }
      }
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
    content {
      status_code           = custom_error_configuration.value.status_code
      custom_error_page_url = custom_error_configuration.value.custom_error_page_url
    }
  }

  dynamic "ssl_certificate" {
    for_each = var.ssl_certificates
    content {
      name                = ssl_certificate.value.name
      data                = ssl_certificate.value.key_vault_secret_id == null ? filebase64(ssl_certificate.value.data) : null
      password            = ssl_certificate.value.key_vault_secret_id == null ? ssl_certificate.value.password : null
      key_vault_secret_id = ssl_certificate.value.key_vault_secret_id
    }
  }
  
  dynamic "trusted_root_certificate" {
    for_each = var.trusted_root_certificate
    content {
      name                = trusted_root_certificate.value.name
      data                = trusted_root_certificate.value.data == null ? try(filebase64(trusted_root_certificate.value.file_path), null) : trusted_root_certificate.value.data
      key_vault_secret_id = trusted_root_certificate.value.key_vault_secret_id
    }
  }

}

