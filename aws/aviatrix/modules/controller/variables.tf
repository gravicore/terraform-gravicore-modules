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
<<<<<<< HEAD
  default = "github.com/gravicore/terraform-gravicore-modules/aws/aviatrix"
=======
  default = "gravicore/terraform-gravicore-modules/aws/aviatrix"
>>>>>>> master
}

# ----------------------------------------------------------------------------------------------------------------------
# Module Custom Variables
# ----------------------------------------------------------------------------------------------------------------------

variable "transit_vpc_name" {
  default = "shared-vpc"
}
