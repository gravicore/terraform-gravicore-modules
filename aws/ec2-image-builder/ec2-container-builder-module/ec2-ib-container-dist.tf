# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "container_dist_name" {
  type        = string
  description = "Name of the Container Distribution Configuration"
}

variable "container_dist_description" {
  type        = string
  description = "Description of the Container Distribution Configuration"
}

variable "container_tags" {
  type        = map(string)
  description = "value of the tags to be added to the container"
}


variable "container_dist_repository_name" {
  type        = string
  description = "Name of the ECR Repository where the image will be pushed"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------


resource "aws_imagebuilder_distribution_configuration" "ec2_ib_container_dist" {
  name = local.module_prefix

  distribution {
    container_distribution_configuration {
      description    = var.container_dist_description
      container_tags = var.container_tags
      target_repository {
        repository_name = var.container_dist_repository_name
        service         = "ECR"
      }
    }
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------


output "container_dist_arn" {
  value = aws_imagebuilder_distribution_configuration.ec2_ib_container_dist.arn
}
