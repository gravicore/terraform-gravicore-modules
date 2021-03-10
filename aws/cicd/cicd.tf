# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "parameter_store_key_arn" {
  type        = string
  default     = ""
  description = "KMS key arn used for secure strings"
}

variable "cicd_elevated_policy_allow" {
  type    = "list"
  default = ["*"]
}

variable "cicd_elevated_policy_deny" {
  type    = "list"
  default = []
}

variable deploy_artifacts_bucket {
  type        = bool
  default     = true
  description = ""
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

data "aws_iam_policy_document" "elevated" {
  statement {
    actions   = var.cicd_elevated_policy_allow
    resources = ["*"]
  }

  statement {
    effect    = length(var.cicd_elevated_policy_deny) > 0 ? "Deny" : "Allow"
    actions   = length(var.cicd_elevated_policy_deny) > 0 ? var.cicd_elevated_policy_deny : var.cicd_elevated_policy_allow
    resources = ["*"]
  }

  statement {
    effect    = "Deny"
    actions   = ["*"]
    resources = ["arn:aws:iam::*:role/OrganizationAccountAccessRole"]
  }
}

resource "aws_iam_policy" "elevated" {
  count = var.create ? 1 : 0
  name  = join(var.delimiter, [local.module_prefix, "elevated", "access"])

  policy = data.aws_iam_policy_document.elevated.json
}

resource "aws_iam_user" "elevated" {
  count = var.create ? 1 : 0
  name  = "${local.module_prefix}-elevated-access"

  tags = local.tags
}

resource "aws_iam_user_policy_attachment" "elevated" {
  count      = var.create ? 1 : 0
  user       = aws_iam_user.elevated[0].name
  policy_arn = aws_iam_policy.elevated[0].arn
}

resource "aws_iam_access_key" "elevated" {
  count = var.create ? 1 : 0
  user  = aws_iam_user.elevated[0].name
}

resource "aws_s3_bucket" "default" {
  count  = var.create && var.deploy_artifacts_bucket ? 1 : 0
  bucket = join(var.delimiter, [local.module_prefix, "artifacts"])
  region = var.aws_region
  acl    = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = local.tags
}

resource "aws_s3_bucket_public_access_block" "default" {
  count  = var.create && var.deploy_artifacts_bucket ? 1 : 0
  bucket = aws_s3_bucket.default[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_ssm_parameter" "service_access_key_id" {
  count       = var.create ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-elevated-access-key-id"
  description = format("%s %s", var.desc_prefix, "CICD Elevated service account Access Key ID")

  type      = "SecureString"
  value     = aws_iam_access_key.elevated[0].id
  overwrite = true
  tags      = local.tags
}

resource "aws_ssm_parameter" "service_access_key_secret" {
  count       = var.create ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-elevated-access-key-secret"
  description = format("%s %s", var.desc_prefix, "CICD Elevated service account Secret Access Key")

  type      = "SecureString"
  value     = aws_iam_access_key.elevated[0].secret
  overwrite = true
  tags      = local.tags
}

resource "aws_ssm_parameter" "cicd_bucket_id" {
  count       = var.create && var.deploy_artifacts_bucket ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-artifacts-bucket-id"
  description = format("%s %s", var.desc_prefix, "CICD arctifacts bucket ID")

  type      = "String"
  value     = aws_s3_bucket.default[0].id
  overwrite = true
  tags      = local.tags
}

resource "aws_ssm_parameter" "cicd_bucket_arn" {
  count       = var.create && var.deploy_artifacts_bucket ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-artifacts-bucket-arn"
  description = format("%s %s", var.desc_prefix, "CICD arctifacts bucket ARN")

  type      = "String"
  value     = aws_s3_bucket.default[0].arn
  overwrite = true
  tags      = local.tags
}
