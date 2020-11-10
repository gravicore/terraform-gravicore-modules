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

variable "container_port" {
  description = "The port of the ECS Task to be exposed"
  default     = "8080"
  type        = string
}

variable "container_cpu" {
  description = "The amount of CPU used by the Task"
  default     = "1"
  type        = string
}

variable "container_memory" {
  description = "The amount of memory used by the Task"
  default     = "1024"
  type        = string
}

variable "container_desired_count" {
  description = "The number of tasks to start"
  type        = string
  default     = "2"
}

variable "container_privileged" {
  type        = bool
  description = "When this variable is `true`, the container is given elevated privileges on the host container instance (similar to the root user). This parameter is not supported for Windows containers or tasks using the Fargate launch type."
  default     = null
}

variable "container_port_mappings" {
  type = list(object({
    containerPort = number
    hostPort      = number
    protocol      = string
  }))
  description = "The port mappings to configure for the container. This is a list of maps. Each map should contain \"containerPort\", \"hostPort\", and \"protocol\", where \"protocol\" is one of \"tcp\" or \"udp\". If using containers in a task with the awsvpc or host network mode, the hostPort can either be left blank or set to the same value as the containerPort"
  default = []
}

variable "container_essential" {
  type        = bool
  description = "Determines whether all other containers in a task are stopped, if this container fails or stops for any reason. Due to how Terraform type casts booleans in json it is required to double quote this value"
  default     = true
}

variable "container_readonly_root_filesystem" {
  type        = bool
  description = "Determines whether a container is given read-only access to its root filesystem. Due to how Terraform type casts booleans in json it is required to double quote this value"
  default     = false
}

variable "container_memory_reservation" {
  type        = number
  description = "The amount of memory (in MiB) to reserve for the container. If container needs to exceed this threshold, it can do so up to the set container_memory hard limit"
  default     = null
}

variable "container_image" {
  type        = string
  description = "The image used to start the container. Images in the Docker Hub registry available by default"
}

variable "container_environment" {
  type = list(object({
    name  = string
    value = string
  }))
  description = "The environment variables to pass to the container. This is a list of maps. map_environment overrides environment"
  default     = []
}

variable "container_command" {
  type        = list(string)
  description = "The command that is passed to the container"
  default     = null
}

variable "container_log_configuration" {
  type        = any
  description = "Log configuration options to send to a custom log driver for the container. For more details, see https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_LogConfiguration.html"
  default     = null
}

variable "container_create_autoscaling" {
  type        = bool
  default     = true
  description = "Set to false to prevent the autoscaling resources from being created"
}

variable "container_autoscaling_role_arn" {
  description = "The arn of the autoscaling role"
  type        = string
}

variable "container_autoscaling_min_capacity" {
  description = "The minimum number of instances to start"
  type        = string
}

variable "container_autoscaling_max_capacity" {
  description = "The maximum number of instances to start"
  type        = string
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

variable "container_datadog_enabled" {
  type        = bool
  description = "Determines whether the logs and metrics container should be created"
  default     = false
}

variable "container_datadog_metrics_cpu" {
  type        = number
  description = "Determines the amount of cpu used by datadog"
  default     = 0
}

variable "container_datadog_api_key" {
  type        = string
  description = "The api key used by datadog"
  default     = ""
}

variable "container_datadog_service_name" {
  type        = string
  description = "The service name used by datadog"
}

variable "container_docker_labels" {
  type        = map(string)
  description = "The configuration options to send to the `docker_labels`"
  default     = null
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

module "container" {
  source                       = "git::https://github.com/cloudposse/terraform-aws-ecs-container-definition.git?ref=0.45.1"
  container_name               = local.module_prefix
  container_image              = var.container_image
  container_memory             = var.container_memory
  container_memory_reservation = var.container_memory_reservation
  container_cpu                = parseint(var.container_cpu, 10) - var.container_datadog_metrics_cpu
  essential                    = var.container_essential
  readonly_root_filesystem     = var.container_readonly_root_filesystem
  environment                  = var.container_environment
  port_mappings                = var.container_port_mappings
  log_configuration            = var.container_log_configuration
  privileged                   = var.container_privileged
  command                      = var.container_command
  docker_labels                = var.container_docker_labels
}

module "datadog" {
  source                         = "./datadog"
  container_datadog_metrics_cpu  = var.container_datadog_metrics_cpu
  container_datadog_api_key      = var.container_datadog_api_key
  container_datadog_service_name = var.container_datadog_service_name
  namespace                      = var.namespace
  environment                    = var.environment
  stage                          = var.stage
  name                           = var.name
  tags                           = local.tags
}

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
  memory                   = var.container_memory
  task_role_arn            = var.container_task_role_arn
  execution_role_arn       = var.container_execution_role_arn
  tags                     = local.tags
  container_definitions    = var.container_datadog_enabled ? jsonencode([
      module.container.json_map_object, 
      module.datadog.datadog_container_logging_definition, 
      module.datadog.datadog_container_metrics_definition
    ]) : jsonencode([ module.container.json_map_object, ])
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
