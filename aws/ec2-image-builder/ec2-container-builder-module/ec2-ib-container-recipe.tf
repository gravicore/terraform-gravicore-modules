# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

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

  name           = local.module_prefix
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


# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------


output "ec2_ib_container_recipe_arn" {
  value = aws_imagebuilder_container_recipe.ec2_ib_container_recipe.arn
}
