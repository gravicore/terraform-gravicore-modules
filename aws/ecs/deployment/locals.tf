locals {
  unique = length(keys(var.services)) == 1
  services = var.create ? {
    for key, value in var.services : key => merge({
      family = local.unique ? local.module_prefix : "${local.module_prefix}-${key}"
    }, value)
  } : {}

  lb_services = var.create ? {
    for key, value in var.services : key => merge(value, {
      lb = merge(value.lb, {
        name   = local.unique ? local.module_prefix : "${local.module_prefix}-${coalesce(value.lb.name, key)}"
        domain = local.unique ? var.name : "${local.module_prefix}-${coalesce(value.lb.name, key)}"
      })
    })
    if value.lb != null && var.create
  } : {}

  lb_http_services = var.create ? {
    for key, value in local.lb_services : key => value
    if value.lb.protocol == "HTTP"
  } : {}

  dd_enable     = var.cluster.task.datadog != null
  dd_ssm_key    = local.dd_enable ? "arn:aws:ssm:${var.aws_region}:${local.account_id}:parameter/${local.stage_prefix}/${var.cluster.task.datadog.ssm_key}" : ""
  dd_enable_log = local.dd_enable ? var.cluster.task.datadog.enable_log : false
  dd_enable_apm = local.dd_enable ? var.cluster.task.datadog.enable_apm : false
  dd_tags = concat(
    [for key, value in local.tags : "${key}:${value}" if value != null],
    ["cluster:${var.cluster.name}"]
  )

  datadog = jsondecode(local.dd_enable ? jsonencode(concat(
    [{
      name              = "${local.module_prefix}-datadog"
      image             = "public.ecr.aws/datadog/agent:7"
      memoryReservation = 50
      essential         = true
      cpu               = 0
      systemControls    = []
      volumesFrom       = []
      mountPoints       = []
      dockerLabels = {
        "com.datadoghq.service_name" = "${local.module_prefix}-router"
      }
      portMappings = [
        {
          hostPort      = 8126
          containerPort = 8126
          protocol      = "tcp"
        },
        {
          hostPort      = 8125
          containerPort = 8125
          protocol      = "udp"
        }
      ]
      environment = [
        {
          name  = "ECS_FARGATE"
          value = "true"
        },
        {
          name  = "DD_APM_ENABLED"
          value = tostring(local.dd_enable_apm)
        },
        {
          name = "DD_CONTAINER_LABELS_AS_TAGS"
          value = jsonencode({
            "com.datadoghq.service_name" = "service_name"
          })
        }
      ]
      secrets = [{
        name      = "DD_API_KEY"
        valueFrom = local.dd_ssm_key
      }]
    }],
    local.dd_enable_log ?
    [{
      image             = "public.ecr.aws/aws-observability/aws-for-fluent-bit:stable"
      name              = "${local.module_prefix}-router"
      memoryReservation = 50
      essential         = true
      cpu               = 0
      systemControls    = []
      volumesFrom       = []
      mountPoints       = []
      environment       = []
      portMappings      = []
      user              = "0"
      dockerLabels = {
        "com.datadoghq.service_name" = "${local.module_prefix}-router"
      }
      firelensConfiguration = {
        type = "fluentbit",
        options = {
          "enable-ecs-log-metadata" : "true"
        }
      }
    }] : []
  )) : jsonencode([]))
}
