module "rds_kms_key" {
  source                  = "git::https://github.com/cloudposse/terraform-aws-kms-key.git?ref=0.1.2"
  namespace               = ""
  stage                   = ""
  name                    = "${local.account_name}-rds"
  description             = "KMS key for rds"
  deletion_window_in_days = 10
  enable_key_rotation     = "true"
  alias                   = "alias/${replace(local.account_name, "-", "/")}/rds"
  tags                    = "${local.tags}"
}

output "rds_key_arn" {
  value       = "${module.rds_kms_key.key_arn}"
  description = "Key ARN"
}

module "workspaces_kms_key" {
  source                  = "git::https://github.com/cloudposse/terraform-aws-kms-key.git?ref=0.1.2"
  namespace               = ""
  stage                   = ""
  name                    = "${local.account_name}-workspaces"
  description             = "KMS key for workspaces"
  deletion_window_in_days = 10
  enable_key_rotation     = "true"
  alias                   = "alias/${replace(local.account_name, "-", "/")}/workspaces"
  tags                    = "${local.tags}"
}

output "workspaces_key_arn" {
  value       = "${module.workspaces_kms_key.key_arn}"
  description = "Key ARN"
}

module "lambda_kms_key" {
  source                  = "git::https://github.com/cloudposse/terraform-aws-kms-key.git?ref=0.1.2"
  namespace               = ""
  stage                   = ""
  name                    = "${local.account_name}-workspaces"
  description             = "KMS key for workspaces"
  deletion_window_in_days = 10
  enable_key_rotation     = "true"
  alias                   = "alias/${replace(local.account_name, "-", "/")}/workspaces"
  tags                    = "${local.tags}"
}

output "lambda_key_arn" {
  value       = "${module.lambda_kms_key.key_arn}"
  description = "Key ARN"
}

module "ssm_kms_key" {
  source                  = "git::https://github.com/cloudposse/terraform-aws-kms-key.git?ref=0.1.2"
  namespace               = ""
  stage                   = ""
  name                    = "${local.account_name}-workspaces"
  description             = "KMS key for workspaces"
  deletion_window_in_days = 10
  enable_key_rotation     = "true"
  alias                   = "alias/${replace(local.account_name, "-", "/")}/workspaces"
  tags                    = "${local.tags}"
}

output "ssm_key_arn" {
  value       = "${module.ssm_kms_key.key_arn}"
  description = "Key ARN"
}

module "ebs_kms_key" {
  source                  = "git::https://github.com/cloudposse/terraform-aws-kms-key.git?ref=0.1.2"
  namespace               = ""
  stage                   = ""
  name                    = "${local.account_name}-workspaces"
  description             = "KMS key for workspaces"
  deletion_window_in_days = 10
  enable_key_rotation     = "true"
  alias                   = "alias/${replace(local.account_name, "-", "/")}/workspaces"
  tags                    = "${local.tags}"
}

output "ebs_key_arn" {
  value       = "${module.ebs_kms_key.key_arn}"
  description = "Key ARN"
}
