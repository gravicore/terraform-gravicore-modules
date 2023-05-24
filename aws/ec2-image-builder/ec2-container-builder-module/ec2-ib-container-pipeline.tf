# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "pipeline_name" {
  type        = string
  description = "Name of the Image Pipeline"
}


variable "pipeline_schedule" {
  type        = string
  description = "cron schedule to run this pipepine on this format cron(0 0 * * ? *)"
}
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

variable "container_recipe_name" {
  type        = string
  description = "Name of the Container Recipe"
}

variable "container_recipe_version" {
  type        = string
  description = "Version of the Container Recipe"
}

variable "container_recipe_parent_image" {
  type        = string
  description = "ARN of the parent image to be used on the EC2 Image Builder Container Recipe"
}

variable "container_recipe_target_repository_name" {
  type        = string
  description = "Target ECR Repository where the built image will be pushed"
}

variable "container_recipe_s3_dockerfile_template_uri" {
  type        = string
  description = "URI of the Dockerfile contained in a S3 bucket"
}



# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_imagebuilder_container_recipe" "ec2_ib_container_recipe" {

  name           = "${local.module_prefix}-container-recipe"
  version        = var.container_recipe_version
  container_type = "DOCKER"
  parent_image   = var.container_recipe_parent_image

  target_repository {
    repository_name = var.container_recipe_target_repository_name
    service         = "ECR"
  }

  component { #This needs to be a map as well
    component_arn = aws_imagebuilder_component.ec2_ib_component.arn

    parameter {
      name  = "Parameter1"
      value = "Value1"
    }
  }

  dockerfile_template_uri = var.recipe_s3_dockerfile_template_uri

}

resource "aws_imagebuilder_distribution_configuration" "ec2_ib_container_dist" {
  name = "${local.module_prefix}-container-dist"

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

resource "aws_imagebuilder_image_pipeline" "ec2_ib_container_pipeline" {

  container_recipe_arn             = aws_imagebuilder_container_recipe.ec2_ib_container_recipe.arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.ec2_ib_container_infrastructure.arn
  name                             = "${local.module_prefix}-container-pipeline"

  schedule {
    schedule_expression = "cron(0 0 * * ? *)"
  }

}


# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "container_dist_arn" {
  value = aws_imagebuilder_distribution_configuration.ec2_ib_container_dist.arn
}

output "ec2_ib_container_recipe_arn" {
  value = aws_imagebuilder_container_recipe.ec2_ib_container_recipe.arn
}
