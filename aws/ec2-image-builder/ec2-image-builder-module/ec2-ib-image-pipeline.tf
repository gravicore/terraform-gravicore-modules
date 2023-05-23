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

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------



resource "aws_imagebuilder_image_pipeline" "ec2_ib_image_pipeline" {

  image_recipe_arn                 = aws_imagebuilder_image_recipe.ec2_ib_image_recipe.arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.ec2_ib_image_infrastructure.arn
  name                             = var.pipeline_name

  schedule {
    schedule_expression = "cron(0 0 * * ? *)"
  }

}


# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------


