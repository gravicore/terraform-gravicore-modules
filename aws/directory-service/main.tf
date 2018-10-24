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
