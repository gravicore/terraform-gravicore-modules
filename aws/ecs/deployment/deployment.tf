# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------
variable "cluster" {
  description = "the cluster created previously to deploy services"
  type = object({
    name = optional(string, "")
    task = optional(object({
      certificate_arn    = optional(string, "")
      execution_role_arn = optional(string, "")
      role_arn           = optional(string, "")
      security_group_ids = optional(list(string), [])
      subnet_ids         = optional(list(string), [])
      vpc_id             = optional(string, "")
      zone_id            = optional(string, "")
      zone_name          = optional(string, "")
    }), {})
  })
  default = {}
}

variable "services" {
  description = "the services to deploy, they can be background tasks or load balanced"
  type = map(object({
    lb = optional(object({
      name     = optional(string, null)
      port     = optional(number, 80)
      protocol = optional(string, "HTTP")
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
locals {
  lb = { for k, v in var.services : k => v if v.lb != null }
}

#----------------------------
resource "aws_cloudwatch_log_group" "this" {
  for_each          = var.create ? var.services : {}
  name              = "/aws/ecs/${local.module_prefix}-${each.key}"
  retention_in_days = each.value.task.retention
  tags              = local.tags
}

resource "aws_ecs_task_definition" "this" {
  for_each                 = var.create ? var.services : {}
  family                   = "${local.module_prefix}-${each.key}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = var.cluster.task.execution_role_arn
  task_role_arn            = var.cluster.task.role_arn
  cpu                      = each.value.task.cpu
  memory                   = each.value.task.memory
  tags                     = local.tags

  container_definitions = jsonencode([{
    name  = "${local.module_prefix}-${each.key}"
    image = each.value.task.image
    portMappings = [for p in each.value.task.ports : {
      hostPort      = tonumber(split("/", p)[0])
      containerPort = tonumber(split("/", p)[0])
      protocol      = try(split("/", p)[1], "tcp")
    }]
    environment = [for var, val in each.value.task.environment : {
      name  = var
      value = val
    } if val != "" && val != null]
    entryPoint = each.value.task.entrypoint
    command    = each.value.task.command
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.this[each.key].name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
    secrets = [for var, val in each.value.task.secrets : {
      name      = var
      valueFrom = val
    }]
  }])

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
}

resource "aws_ecs_service" "this" {
  for_each            = var.create ? var.services : {}
  name                = "${local.module_prefix}-${each.key}"
  cluster             = var.cluster.name
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
    subnets          = var.cluster.task.subnet_ids
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
      container_name   = "${local.module_prefix}-${each.key}"
      container_port   = each.value.lb.port
    }
  }
}

resource "aws_lb" "this" {
  for_each           = var.create ? local.lb : {}
  name               = "${local.stage_prefix}-${coalesce(each.value.lb.name, each.key)}"
  internal           = true
  load_balancer_type = "application"
  security_groups    = var.cluster.task.security_group_ids
  subnets            = var.cluster.task.subnet_ids
  tags               = local.tags

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "this" {
  for_each    = var.create ? local.lb : {}
  name        = "${local.stage_prefix}-${coalesce(each.value.lb.name, each.key)}"
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
  for_each          = { for k, v in local.lb : k => v if v.lb.protocol == "HTTP" }
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
  for_each          = { for k, v in local.lb : k => v if v.lb.protocol == "HTTP" }
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
  for_each        = var.create ? local.lb : {}
  zone_id         = var.cluster.task.zone_id
  name            = join(".", [coalesce(each.value.lb.name, each.key), var.cluster.task.zone_name])
  type            = "CNAME"
  ttl             = 30
  records         = [aws_lb.this[each.key].dns_name]
  allow_overwrite = true
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------
output "services" {
  value = { for k, v in var.services : k => {
    task    = aws_ecs_task_definition.this[k].family
    service = aws_ecs_service.this[k].name
    lb      = v.lb != null ? aws_lb.this[k].arn : null
    domain  = v.lb != null ? aws_route53_record.this[k].name : null
  } if var.create }
}
