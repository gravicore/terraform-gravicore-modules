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
  default = "vpc"
}

variable "aws_region" {
  default = "us-east-1"
}

variable terraform_module {
  default = "github.com/gravicore/terraform-gravicore-modules/aws/vpc"
}

# ----------------------------------------------------------------------------------------------------------------------
# Module Custom Variables
# ----------------------------------------------------------------------------------------------------------------------

variable "cidr_network" {
  default = "10.0"
}
