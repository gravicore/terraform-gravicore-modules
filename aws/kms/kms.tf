module "rds_kms_key" {
  source                  = "git::https://github.com/cloudposse/terraform-aws-kms-key.git?ref=0.2.0"
  namespace               = ""
  stage                   = ""
  name                    = join(var.delimiter, [local.stage_prefix, "rds"])
  description             = join(" ", [var.desc_prefix, "KMS key for RDS"])
  deletion_window_in_days = 10
  enable_key_rotation     = true
  alias                   = "alias/${replace(local.stage_prefix, var.delimiter, "/")}/rds"
  tags                    = local.tags
}

output "rds_key_arn" {
  value       = module.rds_kms_key.key_arn
  description = "Key ARN"
}

module "workspaces_kms_key" {
  source                  = "git::https://github.com/cloudposse/terraform-aws-kms-key.git?ref=0.2.0"
  namespace               = ""
  stage                   = ""
  name                    = "${local.stage_prefix}-workspaces"
  description             = join(" ", [var.desc_prefix, "KMS key for Workspaces"])
  deletion_window_in_days = 10
  enable_key_rotation     = true
  alias                   = "alias/${replace(local.stage_prefix, var.delimiter, "/")}/workspaces"
  tags                    = local.tags
}

output "workspaces_key_arn" {
  value       = module.workspaces_kms_key.key_arn
  description = "Key ARN"
}

module "lambda_kms_key" {
  source                  = "git::https://github.com/cloudposse/terraform-aws-kms-key.git?ref=0.2.0"
  namespace               = ""
  stage                   = ""
  name                    = "${local.stage_prefix}-lambda"
  description             = join(" ", [var.desc_prefix, "KMS key for Lambda"])
  deletion_window_in_days = 10
  enable_key_rotation     = true
  alias                   = "alias/${replace(local.stage_prefix, var.delimiter, "/")}/lambda"
  tags                    = local.tags
}

output "lambda_key_arn" {
  value       = module.lambda_kms_key.key_arn
  description = "Key ARN"
}

module "ssm_kms_key" {
  source                  = "git::https://github.com/cloudposse/terraform-aws-kms-key.git?ref=0.2.0"
  namespace               = ""
  stage                   = ""
  name                    = "${local.stage_prefix}-ssm"
  description             = join(" ", [var.desc_prefix, "KMS key for SSM"])
  deletion_window_in_days = 10
  enable_key_rotation     = true
  alias                   = "alias/${replace(local.stage_prefix, var.delimiter, "/")}/ssm"
  tags                    = local.tags
}

output "ssm_key_arn" {
  value       = module.ssm_kms_key.key_arn
  description = "Key ARN"
}

module "ebs_kms_key" {
  source                  = "git::https://github.com/cloudposse/terraform-aws-kms-key.git?ref=0.2.0"
  namespace               = ""
  stage                   = ""
  name                    = "${local.stage_prefix}-ebs"
  description             = join(" ", [var.desc_prefix, "KMS key for EBS"])
  deletion_window_in_days = 10
  enable_key_rotation     = true
  alias                   = "alias/${replace(local.stage_prefix, var.delimiter, "/")}/ebs"
  tags                    = local.tags
}

output "ebs_key_arn" {
  value       = module.ebs_kms_key.key_arn
  description = "Key ARN"
}

module "chamber_kms_key" {
  source                  = "git::https://github.com/cloudposse/terraform-aws-kms-key.git?ref=0.2.0"
  namespace               = ""
  stage                   = ""
  name                    = "${local.stage_prefix}-chamber"
  description             = join(" ", [var.desc_prefix, "KMS key for Chamber"])
  deletion_window_in_days = 10
  enable_key_rotation     = true
  alias                   = "alias/parameter_store_key"
  tags                    = local.tags
}

output "chamber_key_arn" {
  value       = module.chamber_kms_key.key_arn
  description = "Key ARN"
}
