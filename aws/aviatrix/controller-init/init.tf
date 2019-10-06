# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "admin_email" {
  type        = string
  description = "The administrator's email address that will be used for password recovery as well as for notifications from the Controller"
}

variable "controller_private_ip" {
  type        = string
  description = "The Controller's private IP address"
}

variable "controller_public_ip" {
  type        = string
  description = "The Controller's public IP address"
}

variable "access_account_name" {
  type        = string
  default     = ""
  description = "A friendly name mapping to your AWS account ID"
}

variable "customer_license_id" {
  type        = string
  default     = ""
  description = "The customer license ID is required if using a BYOL controller"
}

variable "parameter_store_kms_arn" {
  type        = "string"
  default     = "alias/parameter_store_key"
  description = "The ARN of a KMS key used to encrypt and decrypt SecretString values"
}

data "aws_kms_key" "parameter_store_key" {
  key_id = "alias/parameter_store_key"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

# Generate and store password

resource "random_password" "admin_password" {
  length      = 16
  min_upper   = 4
  min_lower   = 4
  min_numeric = 4
  min_special = 4
  # override_special = "/@\" "
}

resource "aws_ssm_parameter" "admin_password" {
  name        = "/${local.stage_prefix}/${var.name}-admin-password"
  description = "Aviatrix Controller Admin Password"
  type        = "SecureString"
  # key_id          = "${length(aws_kms_key.parameter_store_key.key_id) > 0 ? var.parameter_store_kms_arn : ""}"
  key_id    = coalesce(data.aws_kms_key.parameter_store_key.key_id, var.parameter_store_kms_arn, "")
  value     = random_password.admin_password.result
  overwrite = true
  tags      = local.tags
}

# Initialize Controller

module "controller_init" {
  source = "git::https://github.com/AviatrixSystems/terraform-modules.git//aviatrix-controller-initialize?ref=terraform_0.12"

  admin_email    = var.admin_email
  admin_password = random_password.admin_password.result

  private_ip = var.controller_private_ip
  public_ip  = var.controller_public_ip

  access_account_name = coalesce(var.access_account_name, local.stage_prefix)
  aws_account_id      = local.account_id
  customer_license_id = var.customer_license_id

  #   lifecycle {
  #     ignore_changes = [
  #       admin_email,
  #       admin_password,
  #       access_account_name,
  #     ]
  #   }
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "controller_private_ip" {
  value       = var.controller_private_ip
  description = "The private IP address of the AWS EC2 instance created for the controller"
}

output "controller_public_ip" {
  value       = var.controller_public_ip
  description = "The public IP address of the AWS EC2 instance created for the controller"
}

output "admin_email" {
  value       = var.admin_email
  description = "The administrator's email address that will be used for password recovery as well as for notifications from the Controller"
}

output "admin_password_param" {
  value       = aws_ssm_parameter.admin_password.name
  description = "SSM Parameter name storing the default password for the Aviatrix Controller"
}

output "lambda_result" {
  value       = module.controller_init.result
  description = "The status of lambda execution"
}
