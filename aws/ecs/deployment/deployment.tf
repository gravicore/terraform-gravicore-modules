# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------
variable "cluster" {
  description = "the cluster created previously to deploy services"
  type = object({
    name = optional(string, "")
    task = optional(object({
      certificate_arn = optional(string, "")
      datadog = optional(object({
        ssm_key     = string
        enable_log  = optional(bool, true)
        enable_apm  = optional(bool, false)
        environment = optional(map(string), {})
      }), null)
      execution_role_arn = optional(string, "")
      task_role_arn      = optional(string, "")
      security_group_ids = optional(list(string), [])
      subnet_ids = optional(object({
        private = optional(list(string), [])
        public  = optional(list(string), [])
      }), {})
      vpc_id    = optional(string, "")
      zone_id   = optional(string, "")
      zone_name = optional(string, "")
    }), {})
  })
  default = {}
}

variable "services" {
  description = "the services to deploy, they can be background tasks or load balanced"
  type = map(object({
    lb = optional(object({
      type      = optional(string, "private")
      name      = optional(string, null)
      port      = optional(number, 80)
      protocol  = optional(string, "HTTP")
      hostnames = optional(list(string), [])
      healthcheck = optional(object({
        path                = optional(string, "/")
        interval            = optional(number, 30)
        timeout             = optional(number, 5)
        healthy_threshold   = optional(number, 2)
        unhealthy_threshold = optional(number, 2)
        matcher             = optional(string, "200")
      }), null)
    }), null)
    task = object({
      image        = string
      ports        = optional(list(string), [])
      retention    = optional(number, 7)
      cpu          = optional(number, 256)
      memory       = optional(number, 512)
      entrypoint   = optional(list(string), [])
      command      = optional(list(string), [])
      environment  = map(string)
      secrets      = optional(map(string), {})
      wait_running = optional(bool, false) # false, or else the pipelines can get locked... for stable services, true would be better
    })
  }))
  default = {}
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "this" {
  for_each          = local.services
  name              = "/aws/ecs/${each.value.family}"
  retention_in_days = each.value.task.retention
  tags              = local.tags
}

resource "aws_ecs_task_definition" "this" {
  for_each                 = local.services
  family                   = each.value.family
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = var.cluster.task.execution_role_arn
  task_role_arn            = var.cluster.task.task_role_arn
  cpu                      = each.value.task.cpu
  memory                   = each.value.task.memory
  tags                     = local.tags

  container_definitions = jsonencode(concat([{
    name           = each.value.family
    image          = each.value.task.image
    entryPoint     = each.value.task.entrypoint
    command        = each.value.task.command
    essential      = true
    cpu            = 0
    systemControls = []
    volumesFrom    = []
    mountPoints    = []
    dockerLabels = local.dd_enable ? {
      "com.datadoghq.service_name" = each.value.family
      "com.datadoghq.ad.tags" = jsonencode(concat(local.dd_tags, [
        "application:${each.value.family}",
        "service:${each.value.family}",
      ]))
    } : {}
    portMappings = [for p in each.value.task.ports : {
      hostPort      = tonumber(split("/", p)[0])
      containerPort = tonumber(split("/", p)[0])
      protocol      = try(split("/", p)[1], "tcp")
    }]
    secrets = [for var, val in each.value.task.secrets : {
      name      = var
      valueFrom = val
    }]
    environment = [
      for name, value in merge(local.tags, each.value.task.environment, local.dd_enable ? merge({
        DD_ENV     = var.stage
        DD_SERVICE = each.value.family
        DD_TAGS = join(",", concat(local.dd_tags, [
          "application:${each.value.family}",
          "service:${each.value.family}",
        ]))
        DD_LOGS_CONFIG_CONTAINER_COLLECT_ALL = tostring(local.dd_enable_log)
        DD_LOGS_ENABLED                      = tostring(local.dd_enable_log)
        DD_APM_ENABLED                       = tostring(local.dd_enable_apm)
      }, var.cluster.task.datadog.environment) : {}) : { name = name, value = value }
      if value != "" && value != null
    ]
    logConfiguration = local.dd_enable_log ? {
      logDriver = "awsfirelens",
      secretOptions = [{
        name      = "apikey"
        valueFrom = local.dd_ssm_key
      }]
      options = {
        Name           = "datadog",
        Host           = "http-intake.logs.datadoghq.com",
        dd_service     = each.value.family,
        dd_source      = "fargate",
        dd_message_key = "log",
        TLS            = "on",
        provider       = "ecs"
        dd_tags = join(",", concat(local.dd_tags, [
          "application:${each.value.family}",
          "service:${each.value.family}",
        ])),
      }
      } : {
      logDriver     = "awslogs"
      secretOptions = []
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.this[each.key].name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }], local.datadog))

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
}

resource "aws_ecs_service" "this" {
  for_each            = local.services
  name                = each.value.family
  cluster             = "arn:aws:ecs:${var.aws_region}:${local.account_id}:cluster/${var.cluster.name}"
  task_definition     = aws_ecs_task_definition.this[each.key].arn
  desired_count       = 1
  scheduling_strategy = "REPLICA"
  launch_type         = "FARGATE"
  tags                = local.tags

  wait_for_steady_state              = each.value.task.wait_running
  deployment_minimum_healthy_percent = "100"
  deployment_maximum_percent         = "200"

  network_configuration {
    security_groups  = var.cluster.task.security_group_ids
    subnets          = var.cluster.task.subnet_ids["private"]
    assign_public_ip = false
  }

  enable_ecs_managed_tags           = true
  health_check_grace_period_seconds = 0
  platform_version                  = "LATEST"
  propagate_tags                    = "SERVICE"

  deployment_controller {
    type = "ECS"
  }

  dynamic "load_balancer" {
    for_each = toset(each.value.lb != null ? [1] : [])
    content {
      target_group_arn = aws_lb_target_group.this[each.key].arn
      container_name   = each.value.family
      container_port   = each.value.lb.port
    }
  }
}

resource "aws_lb" "this" {
  for_each           = local.lb_services
  name               = each.value.lb.name
  internal           = each.value.lb.type == "public" ? false : true
  load_balancer_type = "application"
  security_groups    = var.cluster.task.security_group_ids
  subnets            = var.cluster.task.subnet_ids["${each.value.lb.type}"]
  tags               = local.tags

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "this" {
  for_each    = local.lb_services
  name        = each.value.lb.name
  port        = each.value.lb.port
  protocol    = each.value.lb.protocol
  vpc_id      = var.cluster.task.vpc_id
  target_type = "ip"
  tags        = local.tags

  dynamic "health_check" {
    for_each = toset(each.value.lb.healthcheck != null ? [each.value.lb.healthcheck] : [])
    content {
      path                = health_check.value.path
      interval            = health_check.value.interval
      timeout             = health_check.value.timeout
      healthy_threshold   = health_check.value.healthy_threshold
      unhealthy_threshold = health_check.value.unhealthy_threshold
      matcher             = health_check.value.matcher
    }
  }
}

resource "aws_lb_listener" "http" {
  for_each          = local.lb_http_services
  load_balancer_arn = aws_lb.this[each.key].arn
  port              = each.value.lb.port
  protocol          = "HTTP"
  tags              = local.tags

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  for_each          = local.lb_http_services
  load_balancer_arn = aws_lb.this[each.key].arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.cluster.task.certificate_arn
  tags              = local.tags

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[each.key].arn
  }

  depends_on = [aws_lb_target_group.this]
}

resource "aws_route53_record" "this" {
  for_each        = local.lb_services
  zone_id         = var.cluster.task.zone_id
  name            = join(".", [each.value.lb.domain, var.cluster.task.zone_name])
  type            = "CNAME"
  ttl             = 30
  records         = [aws_lb.this[each.key].dns_name]
  allow_overwrite = true
}

resource "aws_route53_record" "hostnames" {
  for_each = var.create ? merge([for key, value in local.lb_services : {
    for hostname in value.lb.hostnames : "${key}-${hostname}" => {
      lb       = key
      hostname = hostname
  } }]...) : {}
  zone_id         = var.cluster.task.zone_id
  name            = join(".", [each.value.hostname, var.cluster.task.zone_name])
  type            = "CNAME"
  ttl             = 30
  records         = [aws_lb.this[each.value.lb].dns_name]
  allow_overwrite = true
}

resource "aws_iam_role_policy" "datadog_task_role" {
  count = var.create && var.cluster.task.datadog != null ? 1 : 0
  name  = "${local.module_prefix}-datadog"
  role  = split("/", var.cluster.task.task_role_arn)[1]
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ecs:ListClusters",
        "ecs:ListContainerInstances",
        "ecs:DescribeContainerInstances",
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy" "datadog_task_execution" {
  count = var.create && var.cluster.task.datadog != null ? 1 : 0
  name  = "${local.module_prefix}-datadog"
  role  = split("/", var.cluster.task.execution_role_arn)[1]
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "ssm:GetParameters"
        Resource = local.dd_ssm_key
      },
      {
        Effect   = "Allow"
        Action   = "kms:Decrypt"
        Resource = "*"
      }
    ]
  })
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------
output "services" {
  value = { for key, value in var.services : key => {
    task    = aws_ecs_task_definition.this[key].family
    service = aws_ecs_service.this[key].name
    lb      = value.lb != null ? aws_lb.this[key].arn : null
    hostnames = value.lb != null ? concat(
      [aws_route53_record.this[key].name],
      flatten([
        for lb_key, lb_value in local.lb_services : [
          for hostname in lb_value.lb.hostnames : aws_route53_record.hostnames["${lb_key}-${hostname}"].name
        ]
    ])) : []
  } if var.create }
}
