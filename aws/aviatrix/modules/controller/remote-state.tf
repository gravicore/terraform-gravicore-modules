variable "terraform_remote_state_vpc_key" {
  description = "Key for the location of the remote state of the vpc module"
  default     = ""
}

variable "terraform_remote_state_acct_key" {
  description = "Key for the location of the remote state of the acct module"
  default     = ""
}

locals {
  remote_state_vpc_key  = "${coalesce(var.terraform_remote_state_vpc_key, "master/${var.stage}/shared-vpc")}"
  remote_state_acct_key = "${coalesce(var.terraform_remote_state_vpc_key, "master/${var.stage}/acct")}"
}

data "terraform_remote_state" "master_account" {
  backend = "s3"

  config {
    region = "${var.aws_region}"

    # bucket = "${var.namespace}-terraform-remote-state-${var.master_account_id}"
    bucket  = "${var.namespace}-master-prd-tf-state-${var.master_account_id}"
    encrypt = true
    key     = "${local.remote_state_acct_key}/terraform.tfstate"

    # dynamodb_table = "${var.namespace}-terraform-remote-state-lock-125902859862"
    dynamodb_table = "${var.namespace}-master-prd-tf-state-lock"
    role_arn       = "arn:aws:iam::${var.master_account_id}:role/grv_deploy_svc"
  }
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config {
    region = "${var.aws_region}"

    # bucket = "${var.namespace}-terraform-remote-state-${var.master_account_id}"
    bucket  = "${var.namespace}-master-prd-tf-state-${var.master_account_id}"
    encrypt = true
    key     = "${local.remote_state_vpc_key}/terraform.tfstate"

    # dynamodb_table = "${var.namespace}-terraform-remote-state-lock-125902859862"
    dynamodb_table = "${var.namespace}-master-prd-tf-state-lock"
    role_arn       = "arn:aws:iam::${var.master_account_id}:role/grv_deploy_svc"
  }
}
