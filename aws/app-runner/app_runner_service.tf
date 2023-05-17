# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------


variable "access_role_arn" {
  type        = string
  default     = null
  description = "ARN of the IAM role that allows App Runner to access ECR"
}

variable "provisioned_cpu_values" {
  type    = list(number)
  default = [256, 512, 1024, 2048, 4096]
}

variable "provisioned_memory_values" {
  type    = list(number)
  default = [512, 1024, 2048, 4096, 6144, 8192, 10240, 12288]
}

variable "instance_configuration" {
  type        = map(any)
  description = "Configure the CPU, Memory and Role ARN for the App Runner Service"
  default = {
    cpu               = 1024
    memory            = 2048
    instance_role_arn = null
  }
}

variable "runtime_environment_secrets" {
  type        = map(string)
  description = <<EOT
  A map of secrets to be made available to the App Runner service,
  in the form of environment variables,
  where the key is the environment variable and the value is the ARN of the secret from AWS Secrets Manager.
  EOT
  default     = {}
}

variable "runtime_environment_variables" {
  type        = map(string)
  description = "Map of Environment Variables"
  default     = {}
}

variable "service_name" {
  type        = string
  description = "Name of the App Runner service"
  default     = "app-runner-service"
}

variable "image_identifier" {
  type        = string
  description = "The URI of the image that App Runner will deploy"
}

variable "port" {
  type        = string
  description = "The port that the container on App Runner listens on"
  default     = "8080"
}

variable "health_check" {
  type        = map(any)
  description = "Map of Health Check Configuration"
  default = {
    healthy_threshold   = 2
    interval            = 5
    path                = "/"
    protocol            = "HTTP"
    timeout             = 2
    unhealthy_threshold = 2
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------


resource "aws_apprunner_service" "app_runner_service" {
  service_name = var.service_name

  source_configuration {
    auto_deployments_enabled = false

    authentication_configuration {
      access_role_arn = var.aws_iam_role.app_runner_ecr_auth_role.arn # To authenticate with ECR
    }

    image_repository {
      image_configuration {
        port                          = var.port
        runtime_environment_secrets   = var.runtime_environment_secrets
        runtime_environment_variables = var.runtime_environment_variables
        image_identifier              = var.image_identifier
        image_repository_type         = "ECR"
      }
    }

    instance_configuration {
      cpu               = var.instance_configuration.cpu
      memory            = var.instance.configuration.memory
      instance_role_arn = var.instance_configuration.instance_role_arn
    }


    network_configuration {
      egress_configuration {
        egress_type       = "VPC"
        vpc_connector_arn = app_runner_vpc_connector.outputs.vpc_connector_arn
      }
    }
  }

  health_check_configuration {
    healthy_threshold   = var.health_check.healthy_threshold
    interval            = var.health_check.interval
    path                = var.health_check.path
    protocol            = var.health_check.protocol
    timeout             = var.health_check.protocol
    unhealthy_threshold = var.health_check.unhealthy_threshold

  }

  auto_scaling_configuration_arn = aws_apprunner_auto_scaling_configuration_version.auto_scaling_configuration.arn


  tags = local.tags


}

#---------------------------------------
# AUTO SCALING CONFIGURATION
#---------------------------------------

resource "aws_apprunner_auto_scaling_configuration_version" "auto_scaling_configuration" {
  
  depends_on = [ aws_apprunner_service.app_runner_service ]

  auto_scaling_configuration_name = join("-", [var.service_name, "auto-scaling-configuration"])

  max_concurrency = 50
  max_size        = 10
  min_size        = 2

  tags = local.tags

}
