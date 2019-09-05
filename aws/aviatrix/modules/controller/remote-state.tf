data "terraform_remote_state" "master_account" {
  backend = "s3"

  config {
    region = "${var.aws_region}"

    # bucket = "${var.namespace}-terraform-remote-state-${var.master_account_id}"

    bucket  = "${var.namespace}-master-prd-tf-state-${var.master_account_id}"
    encrypt = true
    # key     = "${var.environment}/acct/terraform.tfstate"
    key = "master/prd/acct/terraform.tfstate"
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

    # key     = "${var.environment}/${var.transit_vpc_name}/terraform.tfstate"

    key = "${var.environment}/${var.stage}/${var.transit_vpc_name}/terraform.tfstate"

    # dynamodb_table = "${var.namespace}-terraform-remote-state-lock-125902859862"

    dynamodb_table = "${var.namespace}-master-prd-tf-state-lock"
    role_arn       = "arn:aws:iam::${var.master_account_id}:role/grv_deploy_svc"
  }
}
