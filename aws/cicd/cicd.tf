# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "parameter_store_key_arn" {
  type        = string
  default     = ""
  description = "KMS key arn used for secure strings"
}

variable "cicd_elevated_policy_allow" {
  type    = list(string)
  default = ["*"]
}

variable "cicd_elevated_policy_deny" {
  type    = list(string)
  default = []
}

variable "deploy_artifacts_bucket" {
  type        = bool
  default     = true
  description = ""
}

variable "block_public_acls" {
  type        = bool
  default     = true
  description = ""
}

variable "block_public_policy" {
  type        = bool
  default     = true
  description = ""
}

variable "ignore_public_acls" {
  type        = bool
  default     = true
  description = ""
}

variable "restrict_public_buckets" {
  type        = bool
  default     = true
  description = ""
}

variable "sse_algorithm" {
  type        = string
  default     = "AES256"
  description = "The server-side encryption algorithm to use. Valid values are `AES256` and `aws:kms`"
}

variable "kms_master_key_arn" {
  type        = string
  default     = ""
  description = "The AWS KMS master key ARN used for the `SSE-KMS` encryption. This can only be used when you set the value of `sse_algorithm` as `aws:kms`. The default aws/s3 AWS KMS master key is used if this element is absent while the `sse_algorithm` is `aws:kms`"
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
  name  = join(var.delimiter, [local.module_prefix, "elevated", "access"])

  tags = local.tags
}

resource "aws_iam_group" "elevated" {
  count = var.create ? 1 : 0
  name  = join(var.delimiter, [local.module_prefix, "elevated", "access"])
  path  = "/"
}

resource "aws_iam_group_policy_attachment" "elevated" {
  count      = var.create ? 1 : 0
  group      = concat(aws_iam_group.elevated.*.name, [""])[0]
  policy_arn = concat(aws_iam_policy.elevated.*.arn, [""])[0]
}

resource "aws_iam_group_membership" "elevated" {
  count = var.create ? 1 : 0
  name  = join(var.delimiter, [local.module_prefix, "elevated", "access", "membership"])

  users = [
    concat(aws_iam_user.elevated.*.name, [""])[0]
  ]

  group = concat(aws_iam_group.elevated.*.name, [""])[0]
}

resource "aws_iam_access_key" "elevated" {
  count = var.create ? 1 : 0
  user  = concat(aws_iam_user.elevated.*.name, [""])[0]
}

resource "aws_s3_bucket" "default" {
  count  = var.create && var.deploy_artifacts_bucket ? 1 : 0
  bucket = join(var.delimiter, [local.module_prefix, "artifacts"])
  acl    = "private"

  versioning {
    enabled = true
  }

  tags = local.tags
}

resource "aws_s3_bucket_public_access_block" "default" {
  count  = var.create && var.deploy_artifacts_bucket ? 1 : 0
  bucket = concat(aws_s3_bucket.default.*.id, [""])[0]

  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}

resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  count  = var.create ? 1 : 0
  bucket = concat(aws_s3_bucket.default.*.id, [""])[0]

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_master_key_arn
      sse_algorithm     = var.sse_algorithm
    }
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_ssm_parameter" "service_access_key_id" {
  count       = var.create ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-elevated-access-key-id"
  description = format("%s %s", var.desc_prefix, "CICD Elevated service account Access Key ID")

  type      = "SecureString"
  value     = concat(aws_iam_access_key.elevated.*.id, [""])[0]
  overwrite = true
  tags      = local.tags
}

resource "aws_ssm_parameter" "service_access_key_secret" {
  count       = var.create ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-elevated-access-key-secret"
  description = format("%s %s", var.desc_prefix, "CICD Elevated service account Secret Access Key")

  type      = "SecureString"
  value     = concat(aws_iam_access_key.elevated.*.secret, [""])[0]
  overwrite = true
  tags      = local.tags
}

resource "aws_ssm_parameter" "cicd_bucket_id" {
  count       = var.create && var.deploy_artifacts_bucket ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-artifacts-bucket-id"
  description = format("%s %s", var.desc_prefix, "CICD arctifacts bucket ID")

  type      = "String"
  value     = concat(aws_s3_bucket.default.*.id, [""])[0]
  overwrite = true
  tags      = local.tags
}

resource "aws_ssm_parameter" "cicd_bucket_arn" {
  count       = var.create && var.deploy_artifacts_bucket ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-artifacts-bucket-arn"
  description = format("%s %s", var.desc_prefix, "CICD arctifacts bucket ARN")

  type      = "String"
  value     = concat(aws_s3_bucket.default.*.arn, [""])[0]
  overwrite = true
  tags      = local.tags
}
