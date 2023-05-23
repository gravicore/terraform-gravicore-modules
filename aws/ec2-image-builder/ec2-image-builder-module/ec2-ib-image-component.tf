# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "component_name" {
  type        = string
  description = "Name of the Component"
}

variable "component_version" {
  type        = string
  description = "Version of the component"
}

variable "component_platform" {
  type        = string
  description = "Platform of the component"
}

variable "component_s3_uri" {
  type        = string
  description = "URI of YAML of the component in a S3 bucket"
}

variable "component_kms_key_id" {
  type        = string
  description = "ARN of the KMS key used to encrypt the component"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------


resource "aws_imagebuilder_component" "ec2_ib_image_component" {

  name       = local.module_prefix
  platform   = var.component_platform
  version    = var.component_version
  kms_key_id = var.component_kms_key_id
  tags       = local.tags

  data = yamlencode({
    phases = [{
      name = "build"
      steps = [{
        action = "ExecuteBash"
        inputs = {
          commands = [<<EOT
          echo "hello world"
          sudo yum update -y
          EOT
          ]
        }
        name      = "Hello World"
        onFailure = "Continue"
        },
        {
          name   = "InstallDocker"
          action = "ExecuteBash"
          commands = [<<EOT
          sudo yum install -y docker
          EOT
          ]
      }]
    }]
    schemaVersion = 1.0
  })
}



# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "ec2_ib_component_arn" {
  value = aws_imagebuilder_component.ec2_ib_image_component.arn
}


