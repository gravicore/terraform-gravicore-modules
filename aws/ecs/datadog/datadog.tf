# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "container_datadog_logging_image" {
  type        = string
  description = "The image to start the logging container"
  default     = "amazon/aws-for-fluent-bit:latest"
}

variable "container_datadog_metrics_image" {
  type        = string
  description = "The image to start the metrics container"
  default     = "gcr.io/datadoghq/agent:latest"
}

variable "container_datadog_metrics_cpu" {
  type        = number
  description = "Determines the amount of cpu used by datadog"
  default     = 0
}

variable "container_datadog_api_key" {
  type        = string
  description = "The api key used by datadog"
}

variable "container_datadog_service_name" {
  type        = string
  description = "The service name used by datadog"
}

variable "container_datadog_env_tag" {
  type        = string
  description = "The tag used by datadog to attach statsd"
  default     = "env:none"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

locals {
  datadog_container_logging_definition = {
    image             = var.container_datadog_logging_image,
    name              = "${local.module_prefix}-logging",
    essential         = true,
    memoryReservation = 64
    firelensConfiguration = {
      type = "fluentbit",
      options = {
        enable-ecs-log-metadata = "true"
      }
    },
  }

  datadog_container_metrics_definition = {
    image             = var.container_datadog_metrics_image,
    name              = "${local.module_prefix}-metrics",
    essential         = true,
    cpu               = var.container_datadog_metrics_cpu,
    memoryReservation = 256,
    portMappings = [{
      hostPort      = 8126,
      protocol      = "tcp",
      containerPort = 8126
      }, {
      hostPort      = 8125,
      protocol      = "udp",
      containerPort = 8125
    }]
    environment = [{
      name  = "DD_SERVICE",
      value = "${var.container_datadog_service_name}"
      }, {
      name  = "DD_API_KEY",
      value = "${var.container_datadog_api_key}"
      }, {
      name  = "ECS_FARGATE",
      value = "true"
      }, {
      name  = "DD_PROCESS_AGENT_ENABLED",
      value = "true"
      }, {
      name  = "DD_APM_ENABLED",
      value = "true"
      }, {
      name  = "DD_APM_NON_LOCAL_TRAFFIC",
      value = "true"
      }, {
      name  = "DD_DOGSTATSD_NON_LOCAL_TRAFFIC",
      value = "true"
      }, {
      name  = "DD_DOGSTATSD_TAGS",
      value = "${var.container_datadog_env_tag}"
    }]
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# Outputs
# ----------------------------------------------------------------------------------------------------------------------

output "datadog_container_metrics_definition" {
  value = local.datadog_container_metrics_definition
}

output "datadog_container_logging_definition" {
  value = local.datadog_container_logging_definition
}