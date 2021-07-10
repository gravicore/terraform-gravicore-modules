# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "deletion_window_in_days" {
  type        = number
  default     = 10
  description = "Duration in days after which the key is deleted after destruction of the resource"
}
variable "enable_key_rotation" {
  type        = bool
  default     = true
  description = "Specifies whether key rotation is enabled"
}

variable "alias" {
  type        = string
  default     = ""
  description = "The display name of the alias. The name must start with the word `alias` followed by a forward slash. If not specified, the alias name will be auto-generated."
}
variable "policy" {
  type        = string
  default     = ""
  description = "A valid KMS policy JSON document. Note that if the policy document is not specific enough (but still valid), Terraform may view the policy as constantly changing in a terraform plan. In this case, please make sure you use the verbose/specific version of the policy."
}
variable "key_usage" {
  type        = string
  default     = "ENCRYPT_DECRYPT"
  description = "Specifies the intended use of the key. Valid values: `ENCRYPT_DECRYPT` or `SIGN_VERIFY`."
}
variable "customer_master_key_spec" {
  type        = string
  default     = "SYMMETRIC_DEFAULT"
  description = "Specifies whether the key contains a symmetric key or an asymmetric key pair and the encryption algorithms or signing algorithms that the key supports. Valid values: `SYMMETRIC_DEFAULT`, `RSA_2048`, `RSA_3072`, `RSA_4096`, `ECC_NIST_P256`, `ECC_NIST_P384`, `ECC_NIST_P521`, or `ECC_SECG_P256K1`."
}

variable "backup_resource_ids" {
  type    = list
  default = null
}


# Backup rules
variable "daily_cron" {
}

variable "daily_delete_after" {
}

variable "weekly_cron" {
}

variable "weekly_delete_after" {
}

variable "monthly_cron" {
}

variable "monthly_delete_after" {
}

variable "monthly_cold_storage_after" {
}



variable "selection_tags" {
  type    = list(any)
  default = []
}


# ----------------------------------------------------------------------------------------------------------------------
# IAM Policies
# ----------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role" "aws_backup_role" {
  name               = join("-", [local.module_prefix, "backup-role"])
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": ["sts:AssumeRole"],
      "Effect": "allow",
      "Principal": {
        "Service": ["backup.amazonaws.com"]
      }
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "aws_backup_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.aws_backup_role.name
}


# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

# KMS key for fsx

resource "aws_kms_key" "default" {
  count                    = var.create ? 1 : 0
  deletion_window_in_days  = var.deletion_window_in_days
  enable_key_rotation      = var.enable_key_rotation
  policy                   = var.policy
  tags                     = local.tags
  description              = "KMS for aws backup"
  key_usage                = var.key_usage
  customer_master_key_spec = var.customer_master_key_spec
}

resource "aws_kms_alias" "default" {
  count         = var.create ? 1 : 0
  name          = "alias/${replace(local.stage_prefix, var.delimiter, "/")}/aws-backup"
  target_key_id = join("", aws_kms_key.default.*.id)
}

# AWS Backup vault
resource "aws_backup_vault" "vault" {
  name        = join("-", [local.module_prefix, "vault"])
  kms_key_arn = join("", aws_kms_key.default.*.arn)
}


# AWS Backup plan
resource "aws_backup_plan" "plan" {
  name = join("-", [local.module_prefix, "plan"])

  rule {
    rule_name         = join("-", [local.module_prefix, "daily"])
    target_vault_name = aws_backup_vault.vault.name
    schedule          = var.daily_cron

    lifecycle {
      // default = 5 weeks * 7 days = 35 days
      delete_after = var.daily_delete_after
    }
  }

  rule {
    rule_name         = join("-", [local.module_prefix, "weekly"])
    target_vault_name = aws_backup_vault.vault.name
    schedule          = var.weekly_cron

    lifecycle {
      // default = 3 months * 30 days = 90 days
      delete_after = var.weekly_delete_after
    }
  }

  rule {
    rule_name         = join("-", [local.module_prefix, "monthly"])
    target_vault_name = aws_backup_vault.vault.name
    schedule          = var.monthly_cron

    lifecycle {
      // default = 3 months * 30 days = 90 days
      cold_storage_after = var.monthly_cold_storage_after

      // default = 3 years * 365 days = 1095 days
      delete_after = var.monthly_delete_after
    }
  }
}


# AWS Backup selection - resource arn
resource "aws_backup_selection" "arn_resource_selection" {
  iam_role_arn = aws_iam_role.aws_backup_role.arn
  name         = join("-", [local.module_prefix, "resource"])
  plan_id      = aws_backup_plan.plan.id

  resources = var.backup_resource_ids

  dynamic "selection_tag" {
    for_each = var.selection_tags
    content {
      type  = selection_tags.value.type
      key   = selection_tags.value.key
      value = selection_tags.value.value
    }
  }
}


# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

# Backup Vault
output "vault_id" {
  description = "The name of the vault"
  value       = join("", aws_backup_vault.vault.*.id)
}

output "vault_arn" {
  description = "The ARN of the vault"
  value       = join("", aws_backup_vault.vault.*.arn)
}

output "backup_vault_recovery_points" {
  description = "Backup Vault recovery points"
  value       = join("", aws_backup_vault.vault.*.recovery_points)
}

# Backup Plan
output "plan_id" {
  description = "The id of the backup plan"
  value       = join("", aws_backup_plan.plan.*.id)
}

output "plan_arn" {
  description = "The ARN of the backup plan"
  value       = join("", aws_backup_plan.plan.*.arn)
}

output "plan_version" {
  description = "Unique, randomly generated, Unicode, UTF-8 encoded string that serves as the version ID of the backup plan"
  value       = join("", aws_backup_plan.plan.*.version)
}
