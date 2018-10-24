terraform {
  required_version = "~> 0.11.8"

  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {}
}

provider "aws" {
  version = "~> 1.35"
  region  = "${var.aws_region}"

  assume_role {
    role_arn = "arn:aws:iam::${var.account_id}:role/grv_deploy_svc"
  }
}

locals {
  module_vpc_tags = "${merge(local.tags, map(
    "TerraformModule", "github.com/terraform-aws-modules/terraform-aws-vpc",
    "TerraformModuleVersion", "v1.46.0"))}"
}

module "vpc" {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc?ref=v1.46.0"
  name   = "${local.name_prefix}"
  tags   = "${local.module_vpc_tags}"

  azs                = ["${var.aws_region}a", "${var.aws_region}b"]
  cidr               = "${var.cidr_network}.0.0/16"
  private_subnets    = ["${var.cidr_network}.0.0/19", "${var.cidr_network}.32.0/19"]
  public_subnets     = ["${var.cidr_network}.128.0/20", "${var.cidr_network}.144.0/20"]
  enable_nat_gateway = true
  single_nat_gateway = false
}
