# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------


variable "infra_name" {
  type        = string
  description = "Name of the EC2 Image Builder Service configuration"
}

variable "infra_instance_profile_name" {
  type        = string
  description = "Name of the IAM instance profile to be created"
}

variable "infra_instance_types" {
  type        = list(string)
  description = "List of instance types available for the EC2 Image Builder"
}

variable "infra_key_pair" {
  type        = string
  description = "Name of the key pair to be used for the EC2 Image Builder"
}

variable "infra_security_group_ids" {
  type        = list(string)
  description = "List of security group IDs to be used for the EC2 Image Builder"
}

variable "infra_subnet_id" {
  type        = string
  description = "Subnet ID to be used for the EC2 Image Builder infrastructure"
}

variable "infra_security_group_ids" {
  type        = list(string)
  description = "List of security group IDs to be used for the EC2 Image Builder"
}

variable "infra_sns_topic_arn" {
  type        = string
  description = "SNS topic ARN to be used for the EC2 Image Builder notifications"
}

variable "infra_terminate_instance_on_failure" {
  type        = bool
  description = "Terminate the EC2 Image Builder instance on failure"
}

variable "infra_log_s3_bucket_name" {
  type        = string
  description = "Name of the S3 bucket to be used for the EC2 Image Builder logging"
}

variable "infra_log_s3_key_prefix" {
  type        = string
  description = "Prefix of the S3 bucket objects created by the EC2 Image Builder logging"
}

variable "infra_http_tokens" {
  type        = string
  description = "HTTP tokens to be used for the EC2 Image Builder instance metadata options, valid values are 'optional' or 'required'"
}

variable "infra_http_put_response_hop_limit" {
  type        = number
  description = "HTTP put response hop limit to be used for the EC2 Image Builder instance metadata options"
}


# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------



resource "aws_imagebuilder_infrastructure_configuration" "ec2_ib_image_infrastructure" {
  name                  = "${local.module_prefix}-image-infra"
  instance_profile_name = var.infra_instance_profile_name
  instance_types        = var.infra_instance_types
  key_pair              = var.infra_key_pair

  security_group_ids            = var.infra_security_group_ids
  sns_topic_arn                 = var.infra_sns_topic_arn
  subnet_id                     = var.infra_subnet_id
  terminate_instance_on_failure = var.infra_terminate_instance_on_failure

  logging {
    s3_logs {
      s3_bucket_name = var.infra_log_s3_bucket_name
      s3_key_prefix  = var.infra_log_s3_key_prefix
    }
  }

  instance_metadata_options {
    http_tokens                 = var.infra_http_tokens
    http_put_response_hop_limit = var.infra_http_put_response_hop_limit
  }

  tags = local.tags
}


# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "ec2_ib_infrastructure_configuration_arn" {
  value = aws_imagebuilder_infrastructure_configuration.ec2_ib_image_infrastructure.arn
}
