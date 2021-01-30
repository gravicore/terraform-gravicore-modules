# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "vpc_id" {
  description = "The VPC ID where the ECS will be installed"
  type        = string
}

variable "camunda_admin_user_id" {
  description = "The Admin user id for Camunda"
  type        = string
}

variable "camunda_admin_group_name" {
  description = "The Admin group name for Camunda"
  type        = string
}

variable "camunda_cognito_client_id" {
  description = "The Cognito client id to access"
  type        = string
}

variable "camunda_cognito_redirect_uri" {
  description = "The Cognito user pool to check users"
  type        = string
  default     = ""
}

variable "camunda_cognito_domain" {
  description = "The Cognito user pool to check users"
  type        = string
}

variable "camunda_cognito_user_pool_id" {
  description = "The Cognito user pool to check users"
  type        = string
}

variable "camunda_cognito_signout_uri" {
  description = "The Cognito user pool to check users"
  type        = string
  default     = ""
}

variable "camunda_cognito_sso_signout_uri" {
  description = "The Cognito user pool to check users"
  type        = string
  default     = ""
}

variable "camunda_subnet_ids" {
  type        = list(string)
  description = "A list of subnet IDs to associate with ALB"
}

variable "camunda_image" {
  type        = string
  description = "The image used to start the container. Images in the Docker Hub registry available by default"
}

variable "camunda_cpu" {
  description = "The amount of CPU used by the Task"
  type        = string
  default     = "1024"
}

variable "camunda_cpu_shared" {
  description = "The amount of CPU used by the Task"
  type        = string
  default     = "10"
}

variable "camunda_memory" {
  description = "The amount of memory used by the Task"
  type        = string
  default     = "2048"
}

variable "camunda_port" {
  description = "The port of the API container used by ECS"
  default     = "80"
  type        = string
}

variable "camunda_desired_count" {
  description = "The number of tasks to start"
  type        = string
  default     = "1"
}

variable "camunda_autoscaling_min_capacity" {
  description = "The minimum number of instances to start"
  type        = string
  default     = "1"
}

variable "camunda_autoscaling_max_capacity" {
  description = "The maximum number of instances to start"
  type        = string
  default     = "1"
}

variable "camunda_log_configuration" {
  type        = any
  description = ""
}

variable "camunda_docker_environment" {
  type        = list(any)
  description = ""
  default     = []
}

variable "camunda_docker_labels" {
  type        = any
  description = ""
}

variable "datadog_api_key" {
  type    = string
  default = ""
}

variable "datadog_enabled" {
  type    = bool
  default = false
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
  default     = ""
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
  default     = ["0.0.0.0/0"]
  description = "List of CIDR blocks to allow in HTTPS security group"
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
    port                 = 80
    deregistration_delay = 15
    health_check = {
      enabled             = true
      path                = "/actuator/health"
      protocol            = "HTTP"
      port                = 80
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

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "container" {
  count  = var.create ? 1 : 0
  name   = "${local.module_prefix}-container"
  vpc_id = var.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = var.camunda_port
    to_port         = var.camunda_port
    security_groups = module.alb.security_group_ids
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
  count = var.create ? 1 : 0
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
  count      = var.create ? 1 : 0
  role       = aws_iam_role.execution[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "task" {
  count = var.create ? 1 : 0
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

resource "aws_iam_role_policy" "task" {
  count  = var.create ? 1 : 0
  name   = "${local.module_prefix}-task-policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Effect": "Allow",
          "Action": [
              "ssm:GetParameters",
              "ssm:GetParameter",
              "secretsmanager:GetSecretValue",
              "kms:Decrypt",
              "cognito-identity:Describe*",
              "cognito-identity:Get*",
              "cognito-identity:List*",
              "cognito-idp:Describe*",
              "cognito-idp:AdminGet*",
              "cognito-idp:AdminList*",
              "cognito-idp:List*",
              "cognito-idp:Get*",
              "ecs:ListClusters",
              "ecs:ListContainerInstances",
              "ecs:DescribeContainerInstances"
          ],
          "Resource": [
              "*"
          ]
      }
  ]
}
EOF
  role   = aws_iam_role.task[0].id
}

resource "aws_iam_role" "autoscaling" {
  count = var.create ? 1 : 0
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
  count  = var.create ? 1 : 0
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

module "container" {
  source                   = "git::https://github.com/cloudposse/terraform-aws-ecs-container-definition.git?ref=0.45.1"
  container_name           = local.module_prefix
  container_image          = var.camunda_image
  container_memory         = var.camunda_memory
  container_cpu            = parseint(var.camunda_cpu, 10) - parseint(var.camunda_cpu_shared, 10)
  docker_labels            = var.camunda_docker_labels
  log_configuration        = var.camunda_log_configuration
  essential                = true
  readonly_root_filesystem = false
  privileged               = false
  environment = concat(var.camunda_docker_environment,
    [{
      name  = "SPRING_DATASOURCE_URL",
      value = "jdbc:postgresql://$${/cel-srv-${var.stage}/cmnda-aurora-sls-pg-endpoint}:5432/camunda?gssEncMode=disable"
      }, {
      name  = "SPRING_DATASOURCE_USERNAME",
      value = "$${/cel-srv-${var.stage}/cmnda-aurora-sls-pg-username}"
      }, {
      name  = "SPRING_DATASOURCE_PASSWORD",
      value = "$${/cel-srv-${var.stage}/cmnda-aurora-sls-pg-password}"
      }, {
      name  = "COGNITO_USER_POOL_ID",
      value = "${var.camunda_cognito_user_pool_id}",
      }, {
      name  = "CAMUNDA_ADMIN_USER_ID",
      value = "${var.camunda_admin_user_id}"
      }, {
      name  = "CAMUNDA_ADMIN_GROUP_NAME",
      value = "${var.camunda_admin_group_name}"
      }, {
      name  = "COGNITO_CLIENT_ID",
      value = "${var.camunda_cognito_client_id}"
      }, {
      name  = "COGNITO_REDIRECT_URI",
      value = "${var.camunda_cognito_redirect_uri}"
      }, {
      name  = "COGNITO_DOMAIN",
      value = "${var.camunda_cognito_domain}"
      }, {
      name  = "COGNITO_SIGNOUT_URI",
      value = "${var.camunda_cognito_signout_uri}"
      }, {
      name  = "COGNITO_SSO_SIGNOUT_URI",
      value = "${var.camunda_cognito_sso_signout_uri}"
  }])
  port_mappings = [{
    containerPort = 80,
    hostPort      = 80,
    protocol      = "tcp"
  }]
}

module "alb" {
  source = "git::https://github.com/gravicore/terraform-gravicore-modules.git//aws/alb?ref=0.31.0"

  create                    = var.create
  vpc_id                    = var.vpc_id
  subnet_ids                = var.alb_subnet_ids
  dns_zone_id               = var.alb_dns_zone_id
  dns_zone_name             = var.alb_dns_zone_name
  security_group_ids        = var.alb_security_group_ids
  http_redirect_enabled     = var.alb_http_redirect_enabled
  http_ingress_cidr_blocks  = var.alb_http_ingress_cidr_blocks
  domain_name               = var.alb_domain_name
  certificate_arn           = var.alb_certificate_arn
  https_ports               = var.alb_https_ports
  https_enabled             = var.alb_https_enabled
  https_ingress_cidr_blocks = var.alb_https_ingress_cidr_blocks
  target_groups             = var.alb_target_groups
  namespace                 = var.namespace
  environment               = var.environment
  stage                     = var.stage
  name                      = var.name
  tags                      = local.tags
}

module "datadog" {
  source                         = "git::https://github.com/gravicore/terraform-gravicore-modules.git//aws/datadog/ecs?ref=0.31.0"
  container_datadog_api_key      = var.datadog_api_key
  container_datadog_service_name = var.name
  name                           = var.name
  namespace                      = var.namespace
  environment                    = var.environment
  stage                          = var.stage
  tags                           = local.tags
}

module "ecs" {
  source      = "git::https://github.com/gravicore/terraform-gravicore-modules.git//aws/ecs?ref=0.31.0"
  name        = var.name
  namespace   = var.namespace
  environment = var.environment
  stage       = var.stage
  tags        = local.tags

  create                             = var.create
  vpc_id                             = var.vpc_id
  alb_target_group_arn               = module.alb.target_group_arns[0]
  container_subnet_ids               = var.camunda_subnet_ids
  container_security_group_id        = aws_security_group.container[0].id
  container_execution_role_arn       = aws_iam_role.execution[0].arn
  container_task_role_arn            = aws_iam_role.task[0].arn
  container_cpu                      = var.camunda_cpu
  container_memory_reservation       = var.camunda_memory
  container_desired_count            = var.camunda_desired_count
  container_autoscaling_role_arn     = aws_iam_role.autoscaling[0].arn
  container_autoscaling_min_capacity = var.camunda_autoscaling_min_capacity
  container_autoscaling_max_capacity = var.camunda_autoscaling_max_capacity
  container_create_autoscaling       = true
  container_definitions = var.datadog_enabled ? jsonencode([
    module.container.json_map_object,
    module.datadog.datadog_container_logging_definition,
    module.datadog.datadog_container_metrics_definition
  ]) : jsonencode([module.container.json_map_object, ])

}

resource "aws_ssm_parameter" "access_app_uri" {
  count       = var.create ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-access-app-uri"
  description = format("%s %s", var.desc_prefix, "The WebApp URI for this Camunda instance")

  type      = "String"
  value     = "https://${module.alb.route53_dns_name}/camunda/app/welcome/default/#!/welcome"
  overwrite = true
  tags      = local.tags
}

resource "aws_ssm_parameter" "access_api_uri" {
  count       = var.create ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-access-api-uri"
  description = format("%s %s", var.desc_prefix, "The API URI for this Camunda instance")

  type      = "String"
  value     = "https://${module.alb.route53_dns_name}/engine-rest/engine"
  overwrite = true
  tags      = local.tags
}