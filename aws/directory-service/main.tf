terraform {
  required_version = "~> 0.11.8"

  backend "s3" {}
}

provider "aws" {
  version = "~> 1.35"
  region  = "${var.aws_region}"

  assume_role {
    role_arn = "arn:aws:iam::${var.account_id}:role/grv_deploy_svc"
  }
}

module "application_label" {
  source      = "git::https://github.com/cloudposse/terraform-null-label.git?ref=master"
  namespace   = "${var.namespace}"
  environment = "${var.environment}"
  stage       = "${var.stage}"
  attributes  = ["app"]

  tags = "${merge(var.tags, map(
    "MasterAccountID", "${var.master_account_id}",
    "AccountID", "${var.account_id}",
    "Repository", "${var.repository}"
  ))}"
}
