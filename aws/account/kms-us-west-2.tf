module "rds_kms_key_us_west_2" {
  profile                 = "aws.us-west-2"
  source                  = "git::https://github.com/cloudposse/terraform-aws-kms-key.git?ref=0.1.2"
  namespace               = ""
  stage                   = ""
  name                    = "${local.account_name}-rds"
  description             = "${join(" ", list(var.desc_prefix, "KMS key for RDS"))}"
  deletion_window_in_days = 10
  enable_key_rotation     = "true"
  alias                   = "alias/${replace(local.account_name, "-", "/")}/rds"
  tags                    = "${local.module_kms_key_tags}"
}

output "rds_key_arn_us_west_2" {
  value       = "${module.rds_kms_key.key_arn_us_west_2}"
  description = "Key ARN"
}

module "workspaces_kms_key_us_west_2" {
  profile                 = "aws.us-west-2"
  source                  = "git::https://github.com/cloudposse/terraform-aws-kms-key.git?ref=0.1.2"
  namespace               = ""
  stage                   = ""
  name                    = "${local.account_name}-workspaces"
  description             = "${join(" ", list(var.desc_prefix, "KMS key for Workspaces"))}"
  deletion_window_in_days = 10
  enable_key_rotation     = "true"
  alias                   = "alias/${replace(local.account_name, "-", "/")}/workspaces"
  tags                    = "${local.module_kms_key_tags}"
}

output "workspaces_key_arn_us_west_2" {
  value       = "${module.workspaces_kms_key.key_arn_us_west_2}"
  description = "Key ARN"
}

module "lambda_kms_key_us_west_2" {
  profile                 = "aws.us-west-2"
  source                  = "git::https://github.com/cloudposse/terraform-aws-kms-key.git?ref=0.1.2"
  namespace               = ""
  stage                   = ""
  name                    = "${local.account_name}-lambda"
  description             = "${join(" ", list(var.desc_prefix, "KMS key for Lambda"))}"
  deletion_window_in_days = 10
  enable_key_rotation     = "true"
  alias                   = "alias/${replace(local.account_name, "-", "/")}/lambda"
  tags                    = "${local.module_kms_key_tags}"
}

output "lambda_key_arn_us_west_2" {
  value       = "${module.lambda_kms_key.key_arn_us_west_2}"
  description = "Key ARN"
}

module "ssm_kms_key_us_west_2" {
  profile                 = "aws.us-west-2"
  source                  = "git::https://github.com/cloudposse/terraform-aws-kms-key.git?ref=0.1.2"
  namespace               = ""
  stage                   = ""
  name                    = "${local.account_name}-ssm"
  description             = "${join(" ", list(var.desc_prefix, "KMS key for SSM"))}"
  deletion_window_in_days = 10
  enable_key_rotation     = "true"
  alias                   = "alias/${replace(local.account_name, "-", "/")}/ssm"
  tags                    = "${local.module_kms_key_tags}"
}

output "ssm_key_arn_us_west_2" {
  value       = "${module.ssm_kms_key.key_arn_us_west_2}"
  description = "Key ARN"
}

module "ebs_kms_key_us_west_2" {
  profile                 = "aws.us-west-2"
  source                  = "git::https://github.com/cloudposse/terraform-aws-kms-key.git?ref=0.1.2"
  namespace               = ""
  stage                   = ""
  name                    = "${local.account_name}-ebs"
  description             = "${join(" ", list(var.desc_prefix, "KMS key for EBS"))}"
  deletion_window_in_days = 10
  enable_key_rotation     = "true"
  alias                   = "alias/${replace(local.account_name, "-", "/")}/ebs"
  tags                    = "${local.module_kms_key_tags}"
}

output "ebs_key_arn_us_west_2" {
  value       = "${module.ebs_kms_key.key_arn_us_west_2}"
  description = "Key ARN"
}

module "chamber_kms_key_us_west_2" {
  profile                 = "aws.us-west-2"
  source                  = "git::https://github.com/cloudposse/terraform-aws-kms-key.git?ref=0.1.2"
  namespace               = ""
  stage                   = ""
  name                    = "${local.account_name}-chamber"
  description             = "${join(" ", list(var.desc_prefix, "KMS key for Chamber"))}"
  deletion_window_in_days = 10
  enable_key_rotation     = "true"
  alias                   = "alias/parameter_store_key"
  tags                    = "${local.module_kms_key_tags}"
}

output "chamber_key_arn_us_west_2" {
  value       = "${module.chamber_kms_key.key_arn_us_west_2}"
  description = "Key ARN"
}
