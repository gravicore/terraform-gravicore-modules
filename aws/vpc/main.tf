terraform {
  required_version = "~> 0.11.8"

  # The configuration for this backend will be filled in by Terragrunt
  # backend "s3" {}
}

provider "aws" {
  version = "~> 1.35"
  region  = "${var.aws_region}"

  assume_role {
    role_arn = "arn:aws:iam::${var.account_id}:role/grv_deploy_svc"
  }
}

module "vpc" {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc?ref=v1.46.0"
  name   = "${module.module_label.id}-vpc"

  tags = "${merge(local.default_tags,
    map("TerraformModule", "github.com/terraform-aws-modules/terraform-aws-vpc"),
    map("TerraformModuleVersion", "v1.46.0"))}"

  azs                = ["${var.aws_region}a", "${var.aws_region}b"]
  cidr               = "${var.cidr_network}.0.0/16"
  private_subnets    = ["${var.cidr_network}.0.0/19", "${var.cidr_network}.32.0/19"]
  public_subnets     = ["${var.cidr_network}.128.0/20", "${var.cidr_network}.144.0/20"]
  enable_nat_gateway = true
  single_nat_gateway = false
}

module "module_label" {
  source      = "git::https://github.com/cloudposse/terraform-null-label.git?ref=0.5.3"
  namespace   = "${var.namespace}"
  environment = "${var.environment}"
  stage       = "${var.stage}"

  tags = "${merge(var.tags, map(
    "TerraformModule", "github.com/gravicore/terraform-gravicore-modules",
    "MasterAccountID", "${var.master_account_id}",
    "AccountID", "${var.account_id}",
    "Repository", "${var.repository}"
  ))}"
}
