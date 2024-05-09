# ----------------------------------------------------------------------------------------------------------------------
# CAF resource
# ----------------------------------------------------------------------------------------------------------------------


module "azure_region" {
  source       = "git::https://github.com/gravicore/terraform-gravicore-modules.git//azure/regions?ref=0.46.0"
  azure_region = var.az_region
}


# ----------------------------------------------------------------------------------------------------------------------
# Container App
# ----------------------------------------------------------------------------------------------------------------------


resource "azurerm_container_app" "default" {
  for_each                     = var.create && length(var.container_apps) > 0 ? var.container_apps : {}
  container_app_environment_id = var.container_app_environment_id
  name                         = join(var.delimiter, [local.stage_prefix, var.application, module.azure_region.location_short, each.value.name, var.name])
  revision_mode                = each.value.revision_mode
  resource_group_name          = var.resource_group_name
  tags                         = local.tags


  template {
    max_replicas    = each.value.template.max_replicas
    min_replicas    = each.value.template.min_replicas
    revision_suffix = each.value.template.revision_suffix

    dynamic "azure_queue_scale_rule" {
      for_each = each.value.template.azure_queue_scale_rule == null ? [] : each.value.template.azure_queue_scale_rule

      content {
        name         = azure_queue_scale_rule.value.name
        queue_name   = azure_queue_scale_rule.value.queue_name
        queue_length = azure_queue_scale_rule.value.queue_length

        dynamic "authentication" {
          for_each = azure_queue_scale_rule.value.authentication

          content {
            secret_name       = authentication.value.secret_name
            trigger_parameter = authentication.value.trigger_parameter
          }
        }
      }
    }


    dynamic "custom_scale_rule" {
      for_each = each.value.template.custom_scale_rule == null ? [] : each.value.template.custom_scale_rule

      content {
        name             = custom_scale_rule.value.name
        custom_rule_type = custom_scale_rule.value.custom_rule_type
        metadata         = custom_scale_rule.value.metadata

        dynamic "authentication" {
          for_each = custom_scale_rule.value.authentication == null ? [] : custom_scale_rule.value.authentication

          content {
            secret_name       = authentication.value.secret_name
            trigger_parameter = authentication.value.trigger_parameter
          }
        }
      }
    }


    dynamic "http_scale_rule" {
      for_each = each.value.template.http_scale_rule == null ? [] : each.value.template.http_scale_rule

      content {
        name                = http_scale_rule.value.name
        concurrent_requests = http_scale_rule.value.concurrent_requests

        dynamic "authentication" {
          for_each = http_scale_rule.value.authentication == null ? [] : http_scale_rule.value.authentication

          content {
            secret_name       = authentication.value.secret_name
            trigger_parameter = authentication.value.trigger_parameter
          }
        }
      }
    }

    dynamic "tcp_scale_rule" {
      for_each = each.value.template.tcp_scale_rule == null ? [] : each.value.template.tcp_scale_rule

      content {
        name                = tcp_scale_rule.value.name
        concurrent_requests = tcp_scale_rule.value.concurrent_requests

        dynamic "authentication" {
          for_each = tcp_scale_rule.value.authentication == null ? [] : tcp_scale_rule.value.authentication

          content {
            secret_name       = authentication.value.secret_name
            trigger_parameter = authentication.value.trigger_parameter
          }
        }
      }
    }


    dynamic "container" {
      for_each = tolist(each.value.template.containers)

      content {
        cpu     = container.value.cpu
        image   = container.value.image
        memory  = container.value.memory
        name    = join(var.delimiter, [local.module_prefix, "${container.value.name}"])
        args    = container.value.args
        command = container.value.command

        dynamic "env" {
          for_each = container.value.env == null ? [] : container.value.env

          content {
            name        = env.value.name
            secret_name = env.value.secret_name
            value       = env.value.value
          }
        }
        dynamic "liveness_probe" {
          for_each = container.value.liveness_probe == null ? [] : [container.value.liveness_probe]

          content {
            port                    = liveness_probe.value.port
            transport               = liveness_probe.value.transport
            failure_count_threshold = liveness_probe.value.failure_count_threshold
            host                    = liveness_probe.value.host
            initial_delay           = liveness_probe.value.initial_delay
            interval_seconds        = liveness_probe.value.interval_seconds
            path                    = liveness_probe.value.path
            timeout                 = liveness_probe.value.timeout

            dynamic "header" {
              for_each = liveness_probe.value.header == null ? [] : [liveness_probe.value.header]

              content {
                name  = header.value.name
                value = header.value.value
              }
            }
          }
        }
        dynamic "readiness_probe" {
          for_each = container.value.readiness_probe == null ? [] : [container.value.readiness_probe]

          content {
            port                    = readiness_probe.value.port
            transport               = readiness_probe.value.transport
            failure_count_threshold = readiness_probe.value.failure_count_threshold
            host                    = readiness_probe.value.host
            interval_seconds        = readiness_probe.value.interval_seconds
            path                    = readiness_probe.value.path
            success_count_threshold = readiness_probe.value.success_count_threshold
            timeout                 = readiness_probe.value.timeout

            dynamic "header" {
              for_each = readiness_probe.value.header == null ? [] : [readiness_probe.value.header]

              content {
                name  = header.value.name
                value = header.value.value
              }
            }
          }
        }
        dynamic "startup_probe" {
          for_each = container.value.startup_probe == null ? [] : [container.value.startup_probe]

          content {
            port                    = startup_probe.value.port
            transport               = startup_probe.value.transport
            failure_count_threshold = startup_probe.value.failure_count_threshold
            host                    = startup_probe.value.host
            interval_seconds        = startup_probe.value.interval_seconds
            path                    = startup_probe.value.path
            timeout                 = startup_probe.value.timeout

            dynamic "header" {
              for_each = startup_probe.value.header == null ? [] : [startup_probe.value.header]

              content {
                name  = header.value.name
                value = header.value.name
              }
            }
          }
        }
        dynamic "volume_mounts" {
          for_each = container.value.volume_mounts == null ? [] : [container.value.volume_mounts]

          content {
            name = volume_mounts.value.name
            path = volume_mounts.value.path
          }
        }
      }
    }
    dynamic "volume" {
      for_each = each.value.template.volume == null ? [] : each.value.template.volume

      content {
        name         = volume.value.name
        storage_name = volume.value.storage_name
        storage_type = volume.value.storage_type
      }
    }
  }


  dynamic "dapr" {
    for_each = each.value.dapr == null ? [] : [each.value.dapr]

    content {
      app_id       = dapr.value.app_id
      app_port     = dapr.value.app_port
      app_protocol = dapr.value.app_protocol
    }
  }

  dynamic "identity" {
    for_each = var.identity_ids

    content {
      type         = "UserAssigned"
      identity_ids = compact(var.identity_ids)
    }
  }

  dynamic "ingress" {
    for_each = each.value.ingress == null ? [] : [each.value.ingress]

    content {
      target_port                = ingress.value.target_port
      allow_insecure_connections = ingress.value.allow_insecure_connections
      external_enabled           = ingress.value.external_enabled
      transport                  = ingress.value.transport
      fqdn                       = ingress.value.fqdn

      dynamic "custom_domain" {
        for_each = ingress.value.custom_domain == null ? [] : ingress.value.custom_domain

        content {
          name                     = custom_domain.value.name
          certificate_id           = azurerm_container_app_environment_certificate.default[custom_domain.value.certificate_name].id
          certificate_binding_type = custom_domain.value.certificate_binding_type
        }
      }

      dynamic "traffic_weight" {
        for_each = ingress.value.traffic_weight == null ? [] : [ingress.value.traffic_weight]

        content {
          percentage      = traffic_weight.value.percentage
          label           = traffic_weight.value.label
          latest_revision = traffic_weight.value.latest_revision
          revision_suffix = traffic_weight.value.revision_suffix
        }
      }
    }
  }

  dynamic "registry" {
    for_each = each.value.registry == null ? [] : each.value.registry

    content {
      server               = registry.value.server
      password_secret_name = registry.value.password_secret_name
      username             = registry.value.username
      identity             = registry.value.identity
    }
  }


  dynamic "secret" {
    for_each = data.azurerm_key_vault_secret.secrets

    content {
      name  = local.secret_keys[secret.key]["secret_name"]
      value = secret.value.value
    }
  }

}

data "azurerm_key_vault_secret" "secrets" {
  for_each = local.secret_keys

  name         = each.value["secret_name_in_kv"]
  key_vault_id = var.key_vault_id
}


data "azurerm_key_vault_secret" "certificates" {
  for_each     = toset(local.flattened_certificates)
  name         = each.key
  key_vault_id = var.key_vault_id
}

# data "azurerm_key_vault_secret" "passwords" {
#   for_each      = toset(local.flattened_certificates)
#   name          = "${each.key}-password"
#   key_vault_id  = var.key_vault_id
# }

resource "azurerm_container_app_environment_certificate" "default" {
  for_each                     = toset(local.flattened_certificates)
  name                         = each.key
  container_app_environment_id = var.container_app_environment_id
  certificate_blob_base64      = data.azurerm_key_vault_secret.certificates[each.key].value
  certificate_password         = ""
  # certificate_password          = data.azurerm_key_vault_secret.passwords[each.key].value
}

module "alerts" {
  count               = var.create && (var.metric_alerts != null || var.activity_log_alerts != null) && var.action_group != null ? 1 : 0
  az_region           = var.az_region
  resource_group_name = var.resource_group_name
  source              = "git::https://github.com/gravicore/terraform-gravicore-modules.git//azure/monitor?ref=0.50.3"
  namespace           = var.namespace
  environment         = var.environment
  stage               = var.stage
  application         = var.application
  metric_alerts       = var.metric_alerts
  activity_log_alerts = var.activity_log_alerts
  action_group        = var.action_group
  target_resource_ids = [one(azurerm_postgresql_flexible_server.default[*].id)]
}
