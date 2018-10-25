variable "namespace" {}
variable "environment" {}
variable "stage" {}

variable "master_account_id" {}
variable "account_id" {}

variable "name" {
  default = ""
}

variable "repository" {
  default = "github.com/gravicore/terraform-gravicore-modules/aws/vpc"
}

variable "aws_region" {
  default = "us-east-1"
}

variable "tags" {
  default = {}
}

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
