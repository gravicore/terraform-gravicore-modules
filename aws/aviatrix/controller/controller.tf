# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "vpc_id" {
  type        = string
  description = "The VPC ID where the Controller will be installed"
}

variable "vpc_public_subnets" {
  type        = list(string)
  description = "The public subnet IDs where the Controller instance will reside."
}

variable "key_pair" {
  type        = string
  description = "The name of the AWS Key Pair (required when building an AWS EC2 instance)."
}

variable "aviatrix_role_ec2_name" {
  type        = string
  default     = "aviatrix-role-ec2"
  description = "The name of the aviatrix-ec2-role IAM role"
}

variable "instance_type" {
  type        = string
  default     = "t2.large"
  description = "The instance size for the Aviatrix controller instance"
}

variable "root_volume_size" {
  type        = number
  default     = null
  description = "The size of the hard disk for the controller instance"
}

variable "root_volume_type" {
  type        = string
  default     = "standard"
  description = "The type of the hard disk for the controller instance, Default value is `standard`"
}

variable "incoming_ssl_cidr" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "The CIDR to be allowed for HTTPS(port 443) access to the controller"
}

variable "license_type" {
  type        = string
  default     = "metered"
  description = "The license type for the Aviatrix controller. Valid values are `metered`, `BYOL`"
}

variable "termination_protection" {
  type        = bool
  default     = false
  description = "Whether termination protection is enabled for the controller"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

module "controller" {
  source      = "git::https://github.com/AviatrixSystems/terraform-modules.git//aviatrix-controller-build?ref=terraform_0.12"
  name_prefix = local.module_prefix

  vpc                    = var.vpc_id
  subnet                 = var.vpc_public_subnets[0]
  keypair                = var.key_pair
  ec2role                = var.aviatrix_role_ec2_name
  instance_type          = var.instance_type
  root_volume_size       = var.root_volume_size
  root_volume_type       = var.root_volume_type
  incoming_ssl_cidr      = var.incoming_ssl_cidr
  type                   = var.license_type
  termination_protection = var.termination_protection
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "controller_private_ip" {
  value       = module.controller.private_ip
  description = "The private IP address of the AWS EC2 instance created for the controller"
}

output "controller_public_ip" {
  value       = module.controller.public_ip
  description = "The public IP address of the AWS EC2 instance created for the controller"
}
