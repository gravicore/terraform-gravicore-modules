# data "terraform_remote_state" "aviatrix_controller" {
#   backend = "s3"
#   config {
#     region         = "${var.aws_master_region}"
#     bucket         = "${var.namespace}-master-prd-tf-state-${var.master_account_id}"
#     encrypt        = true
#     key            = "master/prd/avtx-cont/terraform.tfstate"
#     dynamodb_table = "${var.namespace}-master-prd-tf-state-lock"
#     role_arn       = "arn:aws:iam::${var.master_account_id}:role/${var.master_account_assume_role_name}"
#   }
# }

