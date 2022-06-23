# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "vpc_id" {
  description = "The VPC ID where the ECS will be installed"
  type        = string
}

variable "alb_target_group_arn" {
  type        = string
  description = "The ARN of the ALB target group"
  default     = ""
}

variable "container_subnet_ids" {
  description = "A list of private VPC Subnet IDs to launch in"
  type        = list(string)
}

variable "container_security_group_id" {
  description = "The id of the Security Group for the Task"
  type        = string
}

variable "container_execution_role_arn" {
  description = "The arn of the Task Role for execution"
  type        = string
}

variable "container_task_role_arn" {
  description = "The arn of the Task Role for the task"
  type        = string
}

variable "container_cpu" {
  description = "The amount of CPU used by the Task"
  default     = "1024"
  type        = string
}

variable "container_port" {
  description = "The amount of CPU used by the Task"
  default     = "80"
  type        = string
}

variable "container_memory_reservation" {
  description = "The amount of memory used by the Task"
  default     = "2048"
  type        = string
}

variable "container_desired_count" {
  description = "The number of tasks to start"
  type        = string
  default     = "1"
}

variable "container_create_autoscaling" {
  type        = bool
  default     = true
  description = "Set to false to prevent the autoscaling resources from being created"
}

variable "container_autoscaling_role_arn" {
  description = "The arn of the autoscaling role"
  type        = string
  default     = ""
}

variable "container_autoscaling_min_capacity" {
  description = "The minimum number of instances to start"
  type        = string
  default     = ""
}

variable "container_autoscaling_max_capacity" {
  description = "The maximum number of instances to start"
  type        = string
  default     = ""
}

variable "container_autoscaling_predefined_metric_type" {
  description = "The metric to used to scale in or out the tasks"
  type        = string
  default     = "ECSServiceAverageCPUUtilization"
}

variable "container_autoscaling_target_value" {
  description = "The target valud for the metric to scale in or out the tasks"
  type        = string
  default     = "70"
}

variable "container_autoscaling_scale_in_cooldown" {
  description = "The time window before scale in"
  type        = string
  default     = "300"
}

variable "container_autoscaling_scale_out_cooldown" {
  description = "The time window before scale out"
  type        = string
  default     = "300"
}

variable "container_definitions" {
  description = "The container definitions to launch in the cluster"
  type        = string
  default     = ""
}

variable "volume_name" {
  description = ""
  type        = string
  default     = "data-volume"
}

variable "file_system_id" {
  description = ""
  type        = string
  default     = ""
}

variable "volume_root_directory" {
  description = ""
  type        = string
}

variable "volume_credentials_parameter" {
  description = ""
  type        = string
  default     = ""
}

variable "volume_domain" {
  description = ""
  type        = string
  default     = ""
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_ecs_cluster" "default" {
  count = var.create ? 1 : 0
  name  = local.module_prefix
  tags  = local.tags
}

resource "aws_ecs_task_definition" "default" {
  count                    = var.create ? 1 : 0
  family                   = local.module_prefix
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.container_cpu
  memory                   = var.container_memory_reservation
  task_role_arn            = var.container_task_role_arn
  execution_role_arn       = var.container_execution_role_arn
  tags                     = local.tags
  container_definitions    = var.container_definitions

  volume {
    name = var.volume_name

    fsx_windows_file_server_volume_configuration {
      file_system_id = var.volume_file_system_id
      root_directory = var.volume_root_directory

      authorization_config {
        credentials_parameter = var.volume_credentials_parameter
        domain                = var.volume_domain
      }
    }
  }
}

resource "aws_ecs_service" "default" {
  count           = var.create ? 1 : 0
  name            = local.module_prefix
  cluster         = aws_ecs_cluster.default[0].id
  task_definition = aws_ecs_task_definition.default[0].arn
  desired_count   = var.container_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [var.container_security_group_id]
    subnets         = var.container_subnet_ids
  }

  dynamic "load_balancer" {
    for_each = var.alb_target_group_arn == "" ? [] : [1]
    content {
      target_group_arn = var.alb_target_group_arn
      container_name   = local.module_prefix
      container_port   = var.container_port
    }
  }
}

resource "aws_appautoscaling_target" "default" {
  count              = var.create && var.container_create_autoscaling ? 1 : 0
  max_capacity       = var.container_autoscaling_max_capacity
  min_capacity       = var.container_autoscaling_min_capacity
  resource_id        = "service/${aws_ecs_cluster.default[0].name}/${aws_ecs_service.default[0].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  role_arn           = var.container_autoscaling_role_arn
}

resource "aws_appautoscaling_policy" "default" {
  count              = var.create && var.container_create_autoscaling ? 1 : 0
  name               = local.module_prefix
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.default[0].resource_id
  scalable_dimension = aws_appautoscaling_target.default[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.default[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = var.container_autoscaling_predefined_metric_type
    }

    target_value       = var.container_autoscaling_target_value
    scale_in_cooldown  = var.container_autoscaling_scale_in_cooldown
    scale_out_cooldown = var.container_autoscaling_scale_out_cooldown
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# Outputs
# ----------------------------------------------------------------------------------------------------------------------
