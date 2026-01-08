# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "default_deletion_window_in_days" {
  type        = number
  default     = 10
  description = "Duration in days after which the key is deleted after destruction of the resource"
}

variable "default_enable_key_rotation" {
  type        = bool
  default     = true
  description = "Specifies whether key rotation is enabled (default value)"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

module "label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"
}

module "rds_kms_key" {
  source      = "git::https://github.com/cloudposse/terraform-aws-kms-key.git?ref=0.12.1"
  namespace   = ""
  stage       = ""
  name        = join(var.delimiter, [local.stage_prefix, "rds"])
  description = join(" ", [var.desc_prefix, "KMS key for RDS"])
  tags        = local.tags

  deletion_window_in_days = var.default_deletion_window_in_days
  enable_key_rotation     = true
  alias                   = "alias/${replace(local.stage_prefix, var.delimiter, "/")}/rds"
}

module "workspaces_kms_key" {
  source      = "git::https://github.com/cloudposse/terraform-aws-kms-key.git?ref=0.12.1"
  namespace   = ""
  stage       = ""
  name        = "${local.stage_prefix}-workspaces"
  description = join(" ", [var.desc_prefix, "KMS key for Workspaces"])
  tags        = local.tags

  deletion_window_in_days = var.default_deletion_window_in_days
  enable_key_rotation     = true
  alias                   = "alias/${replace(local.stage_prefix, var.delimiter, "/")}/workspaces"
}

module "lambda_kms_key" {
  source      = "git::https://github.com/cloudposse/terraform-aws-kms-key.git?ref=0.12.1"
  namespace   = ""
  stage       = ""
  name        = "${local.stage_prefix}-lambda"
  description = join(" ", [var.desc_prefix, "KMS key for Lambda"])
  tags        = local.tags

  deletion_window_in_days = var.default_deletion_window_in_days
  enable_key_rotation     = true
  alias                   = "alias/${replace(local.stage_prefix, var.delimiter, "/")}/lambda"
}

module "ssm_kms_key" {
  source      = "git::https://github.com/cloudposse/terraform-aws-kms-key.git?ref=0.12.1"
  namespace   = ""
  stage       = ""
  name        = "${local.stage_prefix}-ssm"
  description = join(" ", [var.desc_prefix, "KMS key for SSM"])
  tags        = local.tags

  deletion_window_in_days = var.default_deletion_window_in_days
  enable_key_rotation     = true
  alias                   = "alias/${replace(local.stage_prefix, var.delimiter, "/")}/ssm"
}

module "ebs_kms_key" {
  source                  = "git::https://github.com/cloudposse/terraform-aws-kms-key.git?ref=0.12.1"
  namespace               = ""
  stage                   = ""
  name                    = "${local.stage_prefix}-ebs"
  description             = join(" ", [var.desc_prefix, "KMS key for EBS"])
  deletion_window_in_days = var.default_deletion_window_in_days
  enable_key_rotation     = true
  alias                   = "alias/${replace(local.stage_prefix, var.delimiter, "/")}/ebs"
  tags                    = local.tags
}

module "chamber_kms_key" {
  source      = "git::https://github.com/cloudposse/terraform-aws-kms-key.git?ref=0.12.1"
  namespace   = ""
  stage       = ""
  name        = "${local.stage_prefix}-chamber"
  description = join(" ", [var.desc_prefix, "KMS key for Chamber"])
  tags        = local.tags

  deletion_window_in_days = var.default_deletion_window_in_days
  enable_key_rotation     = true
  alias                   = "alias/parameter_store_key"
}

module "s3_kms_key" {
  source      = "git::https://github.com/cloudposse/terraform-aws-kms-key.git?ref=0.12.1"
  namespace   = ""
  stage       = ""
  name        = "${local.stage_prefix}-s3"
  description = join(" ", [var.desc_prefix, "KMS key for S3"])
  tags        = local.tags

  deletion_window_in_days = var.default_deletion_window_in_days
  enable_key_rotation     = true
  alias                   = "alias/${replace(local.stage_prefix, var.delimiter, "/")}/s3"
}

module "sqs_kms_key" {
  source      = "git::https://github.com/cloudposse/terraform-aws-kms-key.git?ref=0.12.1"
  namespace   = ""
  stage       = ""
  name        = "${local.stage_prefix}-sqs"
  description = join(" ", [var.desc_prefix, "KMS key for SQS"])
  tags        = local.tags

  deletion_window_in_days = var.default_deletion_window_in_days
  enable_key_rotation     = true
  alias                   = "alias/${replace(local.stage_prefix, var.delimiter, "/")}/sqs"
}

module "dnssec_kms_key" {
  ##Must be in us-east-1 only!
  count       = (var.create && var.dnssec_key_create) ? 1 : 0
  source      = "git::https://github.com/cloudposse/terraform-aws-kms-key.git?ref=0.12.1"
  namespace   = ""
  stage       = ""
  name        = "${local.stage_prefix}-dnssec"
  description = join(" ", [var.desc_prefix, "KMS Key for Route 53 DNSSEC KSK"])
  tags        = local.tags

  deletion_window_in_days  = var.default_deletion_window_in_days
  enable_key_rotation      = false ## Rotation MUST be disabled
  customer_master_key_spec = "ECC_NIST_P256"
  multi_region             = false
  key_usage                = "SIGN_VERIFY"
  alias                    = "alias/${replace(local.stage_prefix, var.delimiter, "/")}/dnssec"
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "dnssec-policy"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow Route 53 DNSSEC Service"
        Effect = "Allow"
        Principal = {
          Service = "dnssec-route53.amazonaws.com"
        }
        Action = [
          "kms:DescribeKey",
          "kms:GetPublicKey",
          "kms:Sign"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = var.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:route53:::hostedzone/*"
          }
        }
      },
      {
        Sid    = "Allow Route 53 DNSSEC to CreateGrant"
        Effect = "Allow"
        Principal = {
          Service = "dnssec-route53.amazonaws.com"
        }
        Action   = "kms:CreateGrant"
        Resource = "*"
        Condition = {
          Bool = {
            "kms:GrantIsForAWSResource" = true
          }
        }
      }
    ]
  })
}

module "sns_kms_key" {
  source      = "git::https://github.com/cloudposse/terraform-aws-kms-key.git?ref=0.12.1"
  namespace   = ""
  stage       = ""
  name        = "${local.stage_prefix}-sns"
  description = join(" ", [var.desc_prefix, "KMS Key for SNS"])
  tags        = local.tags

  deletion_window_in_days = var.default_deletion_window_in_days
  enable_key_rotation     = true
  alias                   = "alias/${replace(local.stage_prefix, var.delimiter, "/")}/sns"
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "rds_key_arn" {
  value       = module.rds_kms_key.key_arn
  description = "Generic KMS Key ARN for RDS"
}

output "workspaces_key_arn" {
  value       = module.workspaces_kms_key.key_arn
  description = "Generic KMS Key ARN for Workspaces"
}

output "lambda_key_arn" {
  value       = module.lambda_kms_key.key_arn
  description = "Generic KMS Key ARN for Lambda"
}

output "ssm_key_arn" {
  value       = module.ssm_kms_key.key_arn
  description = "Generic KMS Key ARN for SSM"
}

output "ebs_key_arn" {
  value       = module.ebs_kms_key.key_arn
  description = "Generic KMS Key ARN for EBS"
}

output "chamber_key_arn" {
  value       = module.chamber_kms_key.key_arn
  description = "Generic KMS Key ARN for Chamber"
}

output "s3_key_arn" {
  value       = module.ebs_kms_key.key_arn
  description = "Generic KMS Key ARN for S3"
}

output "sqs_key_arn" {
  value       = module.sqs_kms_key.key_arn
  description = "Generic KMS Key ARN for SQS"
}

output "sns_key_arn" {
  value       = module.sns_kms_key.key_arn
  description = "Generic KMS Key ARN for SSN"
}

output "dnssec_key_arn" {
  value       = var.dnssec_key_create ? concat(module.dnssec_kms_key.*.key_arn, [""])[0] : null
  description = "Generic KMS Key ARN for DNSSEC"
}
