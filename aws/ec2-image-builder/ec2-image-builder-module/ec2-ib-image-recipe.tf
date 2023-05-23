# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

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

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------



resource "aws_imagebuilder_image_recipe" "ec2_ib_image_recipe" {
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

  name         = local.module_prefix
  parent_image = var.image_parent_image
  version      = var.image_recipe_version
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------


output "ec2_ib_image_recipe_arn" {
  value = aws_imagebuilder_image_recipe.ec2_ib_image_recipe.arn
}
