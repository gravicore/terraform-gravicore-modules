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
variable "image_recipe_block_device_name" {
  type        = string
  description = "Name block device to be used on the created AMI ie. '/dev/xvdb' or '/dev/sda'"
}


variable "image_recipe_ebs_configuration" {
  type        = map(any)
  description = "Description of the ebs volume to be used on the created AMI"
  default = {
    delete_on_termination = true
    volume_size           = 100
    volume_type           = "gp3"
    throughput            = 250
  }
}

variable "image_recipe_component" {
  type        = string
  description = "ARN of the components to be installed in the created AMI"
}

variable "image_parent_image" {
  type        = string
  description = "ARN of the parent image to be used on the EC2 Image Builder AMI Recipe"
}


variable "image_recipe_version" {
  type        = string
  description = "Version of the Image Recipe"
}

variable "image_recipe_name" {
  type        = string
  description = "Name of the Image Recipe"
}

variable "ami_tags" {
  type        = map(string)
  description = "Tags to be added to the created AMI"
}


# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------


resource "aws_imagebuilder_image_recipe" "ec2_ib_image_recipe" {


  name         = "${local.module_prefix}-image-recipe"
  parent_image = var.image_parent_image
  version      = var.image_recipe_version

  block_device_mapping {
    device_name = var.image_recipe_block_device_name

    ebs {
      delete_on_termination = var.image_recipe_block_configuration.delete_on_termination
      volume_size           = var.image_recipe_block_configuration.volume_size
      volume_type           = var.image_recipe_block_configuration.volume_type
      throughput            = var.image_recipe_block_configuration.throughput
    }
  }

  component {
    component_arn = var.image_recipe_component

    parameter {
      name  = "Parameter1"
      value = "Value1"
    }
  }

}

resource "aws_imagebuilder_distribution_configuration" "ec2_ib_image_dist" {
  name = "${local.module_prefix}-image-dist"

  distribution {
    ami_distribution_configuration {
      ami_tags = var.ami_tags
      region   = var.aws_region
    }
  }
}

resource "aws_imagebuilder_image_pipeline" "ec2_ib_image_pipeline" {

  image_recipe_arn                 = aws_imagebuilder_image_recipe.ec2_ib_image_recipe.arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.ec2_ib_image_infrastructure.arn
  name                             = "${local.module_prefix}-image-pipeline"

  schedule {
    schedule_expression = "cron(0 0 * * ? *)"
  }

}



# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------



output "ec2_ib_image_recipe_arn" {
  value = aws_imagebuilder_image_recipe.ec2_ib_image_recipe.arn
}
