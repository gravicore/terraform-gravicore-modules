variable "namespace" {}
variable "environment" {}
variable "stage" {}
variable "master_account_id" {}
variable "account_id" {}

variable "repository" {
  default = "github.com/gravicore/terraform-gravicore-modules/aws/vpc"
}

variable "aws_region" {
  default = "us-east-1"
}

variable "tags" {
  default = {}
}

variable "cidr_network" {
  default = "10.0"
}
