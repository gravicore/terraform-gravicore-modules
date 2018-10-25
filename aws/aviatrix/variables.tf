# ----------------------------------------------------------------------------------------------------------------------
# Platform Standard Variables
# ----------------------------------------------------------------------------------------------------------------------

variable "tags" {
  default = {}
}

variable "namespace" {
  default = "grv"
}

variable "environment" {
  default = "master"
}

variable "stage" {
  default = "dev"
}

variable "repository" {
  default = ""
}

variable "master_account_id" {}
variable "account_id" {}

# ----------------------------------------------------------------------------------------------------------------------
# Module Standard Variables
# ----------------------------------------------------------------------------------------------------------------------

variable "name" {
  default = "avtrx"
}

variable "aws_region" {
  default = "us-east-1"
}

variable terraform_module {
  default = "github.com/gravicore/terraform-gravicore-modules/aws/aviatrix"
}

# ----------------------------------------------------------------------------------------------------------------------
# Module Custom Variables
# ----------------------------------------------------------------------------------------------------------------------

variable "aviatrix_controller_username" {
  default = "admin"
}

variable "aviatrix_controller_password" {
  default = "ControllerPSWD#"
}

variable "aviatrix_controller_cloud_type" {
  default = 1
}

variable "aviatrix_gateway_size" {
  default = "t2.micro"
}
