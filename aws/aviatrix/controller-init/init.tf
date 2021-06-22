# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable aviatrix_controller_admin_username {
  description = "The administrator's username for the Aviatrix Controller"
  type        = string
  default     = "admin"
}

variable aviatrix_controller_admin_email {
  description = "The administrator's email address that will be used for password recovery as well as for notifications from the Controller"
  type        = string
}

variable aviatrix_controller_admin_password {
  description = "The administrator's password for the Aviatrix Controller"
  type        = string
}

variable aviatrix_controller_private_ip {
  description = "The Controller's private IP address"
  type        = string
}

variable aviatrix_controller_public_ip {
  description = "The Controller's public IP address"
  type        = string
}

variable aviatrix_controller_access_account_name {
  description = "A friendly name mapping to your AWS account ID"
  type        = string
  default     = ""
}

variable aviatrix_controller_customer_license_id {
  description = "The customer license ID is required if using a BYOL controller"
  type        = string
  default     = ""
}

variable aviatrix_controller_vpc_id {
  type        = string
  description = "VPC in which you want launch Aviatrix controller"
}

variable aviatrix_controller_subnet_id {
  type        = string
  description = "Subnet in which you want launch Aviatrix controller"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

# Initialize Controller

module "controller_init" {
  source = "git::https://github.com/AviatrixSystems/terraform-modules.git//aviatrix-controller-initialize?ref=terraform_0.12"

  admin_email    = var.aviatrix_controller_admin_email
  admin_password = var.aviatrix_controller_admin_password

  public_ip  = var.aviatrix_controller_public_ip
  private_ip = var.aviatrix_controller_private_ip

  vpc_id    = var.aviatrix_controller_vpc_id
  subnet_id = var.aviatrix_controller_subnet_id

  aws_account_id      = local.account_id
  access_account_name = coalesce(var.aviatrix_controller_access_account_name, local.stage_prefix)
  customer_license_id = var.aviatrix_controller_customer_license_id

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

output "aviatrix_controller_init_lambda_result" {
  value       = module.controller_init.result
  description = "The status of lambda execution"
}
