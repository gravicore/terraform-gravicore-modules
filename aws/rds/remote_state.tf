# ----------------------------------------------------------------------------------------------------------------------
# Default Remote State
# ----------------------------------------------------------------------------------------------------------------------

data "terraform_remote_state" "acct" {
  backend = "s3"

  config {
    region         = "${var.aws_region}"
    bucket         = "${var.namespace}-master-prd-tf-state-${var.master_account_id}"
    encrypt        = true
    key            = "master/${var.stage}/acct/terraform.tfstate"
    dynamodb_table = "${var.namespace}-master-prd-tf-state-lock"
    role_arn       = "arn:aws:iam::${var.master_account_id}:role/grv_deploy_svc"
  }
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config {
    region         = "${var.aws_region}"
    bucket         = "${var.namespace}-master-prd-tf-state-${var.master_account_id}"
    encrypt        = true
    key            = "master/${var.stage}/shared-vpc/terraform.tfstate"
    dynamodb_table = "${var.namespace}-master-prd-tf-state-lock"
    role_arn       = "arn:aws:iam::${var.master_account_id}:role/grv_deploy_svc"
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# Application Remote State
# ----------------------------------------------------------------------------------------------------------------------

