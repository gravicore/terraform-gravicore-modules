# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "vpc_id" {
  type        = string
  description = "The VPC ID where the ECS will be installed"
}

variable "container_port" {
  type        = number
  default     = 8080
  description = ""
}

variable "container_image_repo" {
  type        = string
  description = "The image Repo that contains the container image. Images in the Docker Hub registry available by default"
}

variable "container_image_name" {
  type        = string
  description = "name of the container image."
}

variable "container_image_tag" {
  type        = string
  description = "The tag of the container image"
}

variable "container_cpu" {
  type        = string
  default     = "1024"
  description = "The amount of CPU used by the Task"
}

variable "container_cpu_shared" {
  type        = string
  default     = "10"
  description = "The amount of CPU used by the Task"
}

variable "container_memory" {
  type        = string
  default     = "2048"
  description = "The amount of memory used by the Task"
}

variable "container_desired_count" {
  type        = string
  default     = "1"
  description = "The number of tasks to start"
}

variable "container_docker_labels" {
  type        = any
  default     = {}
  description = ""
}

variable "container_autoscaling_min_capacity" {
  type        = string
  default     = "1"
  description = "The minimum number of instances to start"
}

variable "container_autoscaling_max_capacity" {
  type        = string
  default     = "1"
  description = "The maximum number of instances to start"
}

variable "container_log_configuration" {
  type        = any
  default     = null
  description = ""
}

variable "container_docker_environment" {
  type        = list(any)
  default     = []
  description = ""
}

variable "container_subnet_ids" {
  type        = list(string)
  description = "A list of subnet IDs to associate with ALB"
}

variable "alb_subnet_ids" {
  type        = list(string)
  description = "A list of subnet IDs to associate with ALB"
}

variable "alb_security_group_ids" {
  type        = list(string)
  default     = []
  description = "A list of additional security group IDs to allow access to ALB"
}

variable "alb_http_redirect_enabled" {
  type        = bool
  default     = true
  description = "A bool flag to enable/disable HTTP listener"
}

variable "alb_http_ingress_cidr_blocks" {
  type        = list(string)
  default     = ["10.0.0.0/8"]
  description = "List of CIDR blocks to allow in HTTP security group"
}

variable "alb_domain_name" {
  type        = string
  default     = null
  description = ""
}

variable "alb_dns_zone_id" {
  type        = string
  default     = ""
  description = ""
}

variable "alb_dns_zone_name" {
  type        = string
  default     = ""
  description = ""
}

variable "alb_certificate_arn" {
  type        = string
  default     = ""
  description = "The ARN of the default SSL certificate for HTTPS listener"
}

variable "alb_https_ports" {
  type        = list(number)
  default     = [443]
  description = "The port for the HTTPS listener"
}

variable "alb_https_enabled" {
  type        = bool
  default     = true
  description = "A bool flag to enable/disable HTTPS listener"
}

variable "alb_https_ingress_cidr_blocks" {
  type        = list(string)
  default     = ["10.0.0.0/8"]
  description = "List of CIDR blocks to allow in HTTPS security group"
}

variable "internal" {
  type        = bool
  default     = false
  description = ""
}

variable "http2_enabled" {
  type        = bool
  default     = true
  description = ""
}

variable "alb_target_groups" {
  type = list(object({
    target_type          = string
    port                 = number
    protocol             = string
    deregistration_delay = number
    health_check = object({
      enabled             = bool
      path                = string
      interval            = number
      timeout             = number
      healthy_threshold   = number
      unhealthy_threshold = number
      matcher             = string
    })
    stickiness = object({
      type            = string
      cookie_duration = string
      enabled         = bool
    })
  }))
  default = [{
    target_type          = "ip"
    protocol             = "HTTP"
    port                 = 8080
    deregistration_delay = 15
    health_check = {
      enabled             = true
      path                = "/"
      protocol            = "HTTP"
      port                = 8080
      interval            = 15
      timeout             = 10
      healthy_threshold   = 2
      unhealthy_threshold = 8
      matcher             = "200-399"
    }
    stickiness = {
      type            = "lb_cookie"
      cookie_duration = "604800"
      enabled         = false
    }
  }]
  description = "A list of target group resources"
}

variable "retention_in_days" {
  type        = number
  default     = 7
  description = "Specifies the number of days you want to retain log events in the specified log group. Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653, and 0. If you select 0, the events in the log group are always retained and never expire."
}

variable "ecs_logs_kms_key_id" {
  type        = string
  default     = null
  description = "The ARN of the KMS Key to use when encrypting log data. Please note, after the AWS KMS CMK is disassociated from the log group, AWS CloudWatch Logs stops encrypting newly ingested data for the log group. All previously ingested data remains encrypted, and AWS CloudWatch Logs requires permissions for the CMK whenever the encrypted data is requested."
}

variable "port_mappings" {
  type = list(any)
  default = [{
    containerPort = 8080,
    hostPort      = 8080,
    protocol      = "tcp"
  }]
  description = ""
}

variable "scaling_cooldown" {
  type        = string
  default     = "300"
  description = ""
}

variable "container_execution_role_arn" {
  type        = string
  default     = ""
  description = ""
}

variable "container_task_role_arn" {
  type        = string
  default     = ""
  description = ""
}

variable "container_autoscaling_role_arn" {
  type        = string
  default     = ""
  description = ""
}

variable "container_security_group_id" {
  type        = string
  default     = ""
  description = ""
}

variable "secrets" {
  type        = list(any)
  default     = []
  description = <<EOF
  Any secrets to pass into the container at runtime, in the format [{
    name = key-value-of-environment-variable (String, required),
    valueFrom = arn-of-the-secret (String, required, Can be from either AWS Secrets Manager, or AWS Systems Manager Parameter Store)
  }]
  EOF
}

variable "privileged" {
  type        = bool
  default     = false
  description = ""
}

locals {
  container_image = join(":", [join("/", [var.container_image_repo, var.container_image_name]), var.container_image_tag])
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "container" {
  count = var.create && var.container_security_group_id == "" ? 1 : 0
  name  = "${local.module_prefix}-container"

  vpc_id = var.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = var.container_port
    to_port         = var.container_port
    security_groups = module.alb.security_group_ids
  }

  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

resource "aws_iam_role" "execution" {
  count = var.create && var.container_execution_role_arn == "" ? 1 : 0
  name  = "${local.module_prefix}-execution-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "execution" {
  count      = var.create && var.container_execution_role_arn == "" ? 1 : 0
  role       = aws_iam_role.execution[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "task" {
  count = var.create && container_task_role_arn == "" ? 1 : 0
  name  = "${local.module_prefix}-task-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF

  tags = local.tags
}

resource "aws_iam_role" "autoscaling" {
  count = var.create && container_autoscaling_role_arn == "" ? 1 : 0
  name  = "${local.module_prefix}-autoscaling-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "application-autoscaling.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags = local.tags
}

resource "aws_iam_role_policy" "autoscaling" {
  count  = var.create && container_autoscaling_role_arn == "" ? 1 : 0
  name   = "${local.module_prefix}-autoscaling-policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Effect": "Allow",
          "Action": [
              "ecs:DescribeServices",
              "ecs:UpdateService",
              "cloudwatch:PutMetricAlarm",
              "cloudwatch:DescribeAlarms",
              "cloudwatch:DeleteAlarms"
          ],
          "Resource": [
              "*"
          ]
      }
  ]
}
EOF
  role   = aws_iam_role.autoscaling[0].id
}

module "alb" {
  source = "git::https://github.com/gravicore/terraform-gravicore-modules.git//aws/alb?ref=0.31.0"
  create = var.create

  vpc_id                                  = var.vpc_id
  subnet_ids                              = var.alb_subnet_ids
  dns_zone_id                             = var.alb_dns_zone_id
  dns_zone_name                           = var.alb_dns_zone_name
  security_group_ids                      = var.alb_security_group_ids
  http_redirect_enabled                   = var.alb_http_redirect_enabled
  http_ingress_cidr_blocks                = var.alb_http_ingress_cidr_blocks
  domain_name                             = var.alb_domain_name
  certificate_arn                         = var.alb_certificate_arn
  https_ports                             = var.alb_https_ports
  https_enabled                           = var.alb_https_enabled
  https_ingress_cidr_blocks               = var.alb_https_ingress_cidr_blocks
  target_groups                           = var.alb_target_groups
  namespace                               = var.namespace
  environment                             = var.environment
  stage                                   = var.stage
  name                                    = var.name
  internal                                = var.internal
  http2_enabled                           = var.http2_enabled
  alb_access_logs_s3_bucket_force_destroy = true

  tags = local.tags
}

module "container" {
  source         = "git::https://github.com/cloudposse/terraform-aws-ecs-container-definition.git?ref=0.45.1"
  container_name = local.module_prefix

  container_image  = local.container_image
  container_memory = var.container_memory
  container_cpu    = parseint(var.container_cpu, 10) - parseint(var.container_cpu_shared, 10)
  docker_labels    = var.container_docker_labels
  log_configuration = {
    logDriver = "awslogs"
    "options" : {
      "awslogs-group" : "${concat(aws_cloudwatch_log_group.default.*.name, [""])[0]}",
      "awslogs-region" : "${var.aws_region}",
      "awslogs-stream-prefix" : "ecs"
    }
  }
  essential                = true
  readonly_root_filesystem = false
  privileged               = var.privileged
  environment              = var.container_docker_environment
  port_mappings            = var.port_mappings
  secrets                  = var.secrets
}

module "ecs" {
  source = "git::https://github.com/gravicore/terraform-gravicore-modules.git//aws/ecs?ref=0.31.0"
  name   = var.name
  create = var.create

  namespace                                = var.namespace
  environment                              = var.environment
  stage                                    = var.stage
  vpc_id                                   = var.vpc_id
  alb_target_group_arn                     = module.alb.target_group_arns[0]
  container_subnet_ids                     = var.container_subnet_ids
  container_security_group_id              = aws_security_group.container[0].id
  container_execution_role_arn             = var.container_execution_role_arn
  container_task_role_arn                  = var.container_task_role_arn
  container_cpu                            = var.container_cpu
  container_memory_reservation             = var.container_memory
  container_desired_count                  = var.container_desired_count
  container_autoscaling_role_arn           = var.container_autoscaling_role_arn
  container_autoscaling_min_capacity       = var.container_autoscaling_min_capacity
  container_autoscaling_max_capacity       = var.container_autoscaling_max_capacity
  container_create_autoscaling             = true
  container_definitions                    = jsonencode([module.container.json_map_object])
  container_port                           = var.container_port
  container_autoscaling_scale_in_cooldown  = var.scaling_cooldown
  container_autoscaling_scale_out_cooldown = var.scaling_cooldown

  tags = local.tags
}

resource "aws_cloudwatch_log_group" "default" {
  count = var.create ? 1 : 0
  name  = local.module_prefix

  retention_in_days = var.retention_in_days
  kms_key_id        = var.ecs_logs_kms_key_id

  tags = local.tags
}

# ----------------------------------------------------------------------------------------------------------------------
# Outputs
# ----------------------------------------------------------------------------------------------------------------------

output "container_security_group_id" {
  value = concat(aws_security_group.container.*.id, [""])[0]
}

output "container_execution_role_arn" {
  value = concat(aws_iam_role.execution.*.arn, [""])[0]
}

output "container_task_role_arn" {
  value = concat(aws_iam_role.task.*.arn, [""])[0]
}

output "container_autoscaling_role_arn" {
  value = concat(aws_iam_role.autoscaling.*.arn, [""])[0]
}
