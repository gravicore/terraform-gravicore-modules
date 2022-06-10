# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "service_name" {
  description = "(Forces new resource) Name of the service"
  default     = ""
  type        = string
}


variable "auto_scaling_configuration_arn" {
  description = "ARN of an App Runner automatic scaling configuration resource that you want to associate with your service. If not provided, App Runner associates the latest revision of a default auto scaling configuration"
  default     = ""
  type        = string
}

variable "kms_key" {
  description = "(Required) The ARN of the KMS key used for encryption."
  default     = []
  type        = list(string)
}

variable "healthy_threshold" {
  description = "(Optional) The number of consecutive checks that must succeed before App Runner decides that the service is healthy. Defaults to 1. Minimum value of 1. Maximum value of 20."
  default     = 1
  type        = number
}

variable "interval" {
  description = "(Optional) The time interval, in seconds, between health checks. Defaults to 5. Minimum value of 1. Maximum value of 20."
  default     = 5
  type        = number
}

variable "path" {
  description = "(Optional) The URL to send requests to for health checks. Defaults to /. Minimum length of 0. Maximum length of 51200."
  default     = "/"
  type        = string
}

variable "protocol" {
  description = "(Optional) The IP protocol that App Runner uses to perform health checks for your service. Valid values: TCP, HTTP. Defaults to TCP. If you set protocol to HTTP, App Runner sends health check requests to the HTTP path specified by path"
  default     = "TCP"
  type        = string
}

variable "timeout" {
  description = "(Optional) The time, in seconds, to wait for a health check response before deciding it failed. Defaults to 2. Minimum value of 1. Maximum value of 20."
  default     = 2
  type        = number
}

variable "unhealthy_threshold" {
  description = "(Optional) The number of consecutive checks that must fail before App Runner decides that the service is unhealthy. Defaults to 5. Minimum value of 1. Maximum value of 20."
  default     = 5
  type        = number
}

variable "cpu" {
  description = "(Optional) The number of CPU units reserved for each instance of your App Runner service represented as a String. Defaults to 1024. Valid values: 1024|2048|(1|2) vCPU"
  default     = 1024
  type        = number
}

variable "instance_role_arn" {
  description = "(Optional) The Amazon Resource Name (ARN) of an IAM role that provides permissions to your App Runner service. These are permissions that your code needs when it calls any AWS APIs."
  default     = ""
  type        = string
}

variable "memory" {
  description = "(Optional) The amount of memory, in MB or GB, reserved for each instance of your App Runner service. Defaults to 2048. Valid values: 2048|3072|4096|(2|3|4) GB"
  default     = 2048
  type        = number
}

variable "egress_type" {
  description = "(Optional) The type of egress configuration.Set to DEFAULT for access to resources hosted on public networks.Set to VPC to associate your service to a custom VPC specified by VpcConnectorArn."
  default     = "VPC"
  type        = string
}

variable "vpc_connector_arn" {
  description = "The Amazon Resource Name (ARN) of the App Runner VPC connector that you want to associate with your App Runner service. Only valid when EgressType = VPC."
  default     = ""
  type        = string
}

variable "access_role_arn" {
  description = "(Optional) ARN of the IAM role that grants the App Runner service access to a source repository. Required for ECR image repositories (but not for ECR Public)"
  default     = ""
  type        = string
}

variable "connection_arn" {
  description = "(Optional) ARN of the App Runner connection that enables the App Runner service to connect to a source repository. Required for GitHub code repositories."
  default     = null
  type        = string
}

variable "auto_deployments_enabled" {
  description = "(Optional) Whether continuous integration from the source repository is enabled for the App Runner service. If set to true, each repository change (source code commit or new image version) starts a deployment. Defaults to true"
  default     = true
  type        = bool
}

variable "build_command" {
  description = "(Optional) The command App Runner runs to build your application."
  default     = null
  type        = string
}

variable "runtime" {
  description = "(Required) A runtime environment type for building and running an App Runner service. Represents a programming language runtime. Valid values: PYTHON_3, NODEJS_12"
  default     = "PYTHON_3"
  type        = string
}

variable "runtime_environment_variables" {
  description = "(Optional) Environment variables available to your running App Runner service. A map of key/value pairs. Keys with a prefix of AWSAPPRUNNER are reserved for system use and aren't valid"
  default     = {}
  type        = map(any)
}

variable "start_command" {
  description = "(Optional) The command App Runner runs to start your application."
  default     = null
  type        = string
}

variable "configuration_source" {
  description = "(Required) The source of the App Runner configuration. Valid values: REPOSITORY, API"
  default     = "API"
  type        = string
}

variable "repository_url" {
  description = "(Required) The location of the repository that contains the source code."
  default     = []
  type        = list(string)
}

variable "type" {
  description = "(Required) The type of version identifier. For a git-based repository, branches represent versions. Valid values: BRANCH"
  default     = "BRANCH"
  type        = string
}

variable "value" {
  description = "(Required) A source code version. For a git-based repository, a branch name maps to a specific version. App Runner uses the most recent commit to the branch."
  default     = null
  type        = string
}

variable "image_port" {
  description = "(Optional) The port that your application listens to in the container. Defaults to 8080"
  default     = 8080
  type        = number
}

variable "image_identifier" {
  description = "(Required) The identifier of an image. For an image in Amazon Elastic Container Registry (Amazon ECR), this is an image name."
  default     = []
  type        = list(string)
}

variable "image_repository_type" {
  description = "(Required) The type of the image repository. This reflects the repository provider and whether the repository is private or public. Valid values: ECR , ECR_PUBLIC"
  default     = "ECR"
  type        = string
}

variable "subnets" {
  description = "(Required) A list of IDs of subnets that App Runner should use when it associates your service with a custom Amazon VPC. Specify IDs of subnets of a single Amazon VPC. App Runner determines the Amazon VPC from the subnets you specify."
  default     = [""]
  type        = list(string)
}

variable "security_groups" {
  description = "A list of IDs of security groups that App Runner should use for access to AWS resources under the specified subnets. If not specified, App Runner uses the default security group of the Amazon VPC. The default security group allows all outbound traffic."
  default     = null
  type        = list(string)
}

variable "sg_vpc_id" {
  description = "(Optional, Forces new resource) VPC ID."
  type        = string
}

variable "max_concurrency" {
  description = "(Optional, Forces new resource) The maximal number of concurrent requests that you want an instance to process. When the number of concurrent requests goes over this limit, App Runner scales up your service"
  default     = 25
  type        = number
}

variable "max_size" {
  description = "(Optional, Forces new resource) The maximal number of instances that App Runner provisions for your service."
  default     = 10
  type        = number
}

variable "min_size" {
  description = "(Optional, Forces new resource) The minimal number of instances that App Runner provisions for your service."
  default     = 1
  type        = number
}

variable "revoke_rules_on_delete" {
  description = "(Optional, Forces new resource) Whether to revoke the rules associated with the service when the service is deleted. If set to true, App Runner removes the rules associated with the service. If set to false, App Runner keeps the rules associated with the service."
  default     = false
  type        = bool
}

variable "source_code_version_value" {
  description = "(Required) A source code version. For a git-based repository, a branch name maps to a specific version. App Runner uses the most recent commit to the branch."
  default     = null
  type        = string
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_apprunner_service" "default" {
  count        = var.create ? 1 : 0
  service_name = var.service_name == "" ? local.module_prefix : var.service_name

  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.access_role[0].arn
      connection_arn  = var.connection_arn
    }

    auto_deployments_enabled = var.auto_deployments_enabled


    dynamic image_repository {
      for_each = toset(var.image_identifier)
      content {
        image_configuration {
          port                          = var.image_port
          runtime_environment_variables = var.runtime_environment_variables
          start_command                 = var.start_command
        }
        image_identifier      = var.image_identifier
        image_repository_type = var.image_repository_type
      }
    }

    # TODO: Update to choose dynamically
    dynamic code_repository {
      for_each = tolist(var.repository_url)
      content {
        code_configuration {
          code_configuration_values {
            for_each                      = var.repository_url
            build_command                 = var.build_command
            runtime                       = var.runtime
            runtime_environment_variables = var.runtime_environment_variables
            start_command                 = var.start_command
          }
          configuration_source = var.configuration_source
        }

        repository_url = var.repository_url

        source_code_version {
          for_each = var.repository_url
          # ? Hard coded because only 1 possible value? see documentation
          type = "BRANCH"
          # ? ***********************************************************
          value = var.source_code_version_value
        }
      }
    }
  }

  # TODO: Fix this block
  dynamic encryption_configuration {
    for_each = toset(var.kms_key)
    content {
      kms_key = each.key
    }
  }

  auto_scaling_configuration_arn = var.auto_scaling_configuration_arn == "" ? aws_apprunner_auto_scaling_configuration_version.default[0].arn : var.auto_scaling_configuration_arn

  health_check_configuration {
    healthy_threshold   = var.healthy_threshold
    interval            = var.interval
    path                = var.path
    protocol            = var.protocol
    timeout             = var.timeout
    unhealthy_threshold = var.unhealthy_threshold
  }

  instance_configuration {
    cpu               = var.cpu
    memory            = var.memory
    instance_role_arn = var.instance_role_arn == "" ? aws_iam_role.instance_role[0].arn : var.instance_role_arn
  }

  network_configuration {
    egress_configuration {
      egress_type       = var.egress_type
      vpc_connector_arn = var.vpc_connector_arn == "" ? aws_apprunner_vpc_connector.default[0].arn : var.vpc_connector_arn
    }
  }

  tags = var.tags
}

resource "aws_apprunner_vpc_connector" "default" {
  count              = var.create && var.vpc_connector_arn == "" ? 1 : 0
  vpc_connector_name = join(var.delimiter, [local.module_prefix, "vpc-connector"])
  tags               = var.tags

  subnets         = var.subnets
  security_groups = [aws_security_group.apprunner_sg[0].id]
}

resource "aws_apprunner_auto_scaling_configuration_version" "default" {
  count                           = var.create && var.auto_scaling_configuration_arn == "" ? 1 : 0
  auto_scaling_configuration_name = join(var.delimiter, [local.module_prefix, "ascv"])
  tags                            = var.tags

  max_concurrency = var.max_concurrency
  max_size        = var.max_size
  min_size        = var.min_size
}

resource "aws_security_group" "apprunner_sg" {
  count       = var.create ? 1 : 0
  name        = join(var.delimiter, [local.module_prefix, "apprunner-sg"])
  description = "controls access to the ${local.module_prefix} Apprunner service"
  vpc_id      = var.sg_vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "instance_role" {
  count              = var.create ? 1 : 0
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "tasks.apprunner.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
  EOF

  name = join(var.delimiter, [local.module_prefix, "instance-role"])
  tags = local.tags

  # TODO: Update and narrow usage policy, add variable
  managed_policy_arns = ["arn:aws:iam::aws:policy/AdministratorAccess"]
}

# ?WHY NO ASSUME PROPERLY?
resource "aws_iam_role" "access_role" {
  count              = var.create ? 1 : 0
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "build.apprunner.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
  EOF

  name = join(var.delimiter, [local.module_prefix, "access-role"])
  tags = local.tags

  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"]
}


# ----------------------------------------------------------------------------------------------------------------------
# Outputs
# ----------------------------------------------------------------------------------------------------------------------

output "service_id" {
  value = aws_apprunner_service.default[0].service_id
}

output "service_url" {
  value = aws_apprunner_service.default[0].service_url
}

output "arn" {
  value = aws_apprunner_service.default[0].arn
}
