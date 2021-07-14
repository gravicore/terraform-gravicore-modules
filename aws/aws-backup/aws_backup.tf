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

variable "selection_tags" {
  type    = list(any)
  default = []
}

variable "rules" {
  description = "A list of rule maps"
  type        = any
  default     = []
}

variable "vault_name" {
  description = "Name of the backup vault to create. If not given, AWS use default"
  type        = string
  default     = null
}

variable "rule_lifecycle_cold_storage_after" {
  description = "Specifies the number of days after creation that a recovery point is moved to cold storage"
  type        = number
  default     = null
}

variable "rule_lifecycle_delete_after" {
  description = "Specifies the number of days after creation that a recovery point is deleted. Must be 90 days greater than `cold_storage_after`"
  type        = number
  default     = null
}

variable "rule_copy_action_destination_vault_arn" {
  description = "An Amazon Resource Name (ARN) that uniquely identifies the destination backup vault for the copied backup."
  type        = string
  default     = null
}

variable "rule_name" {
  description = "An display name for a backup rule"
  type        = string
  default     = null
}

variable "rule_schedule" {
  description = "A CRON expression specifying when AWS Backup initiates a backup job"
  type        = string
  default     = null
}

variable "rule_enable_continuous_backup" {
  description = " Enable continuous backups for supported resources."
  type        = bool
  default     = false
}

variable "iam_role_arn" {
  description = "If configured, the module will attach this role to selections, instead of creating IAM resources by itself"
  type        = string
  default     = null
}

locals {

  # Rule
  rule = var.rule_name == null ? [] : [
    {
      name              = var.rule_name
      target_vault_name = var.vault_name != null ? var.vault_name : "Default"
      schedule          = var.rule_schedule
      lifecycle = var.rule_lifecycle_cold_storage_after == null ? {} : {
        cold_storage_after = var.rule_lifecycle_cold_storage_after
        delete_after       = var.rule_lifecycle_delete_after
      }
      enable_continuous_backup = var.rule_enable_continuous_backup
    }
  ]

  # Rules
  rules = concat(local.rule, var.rules)

}
# ----------------------------------------------------------------------------------------------------------------------
# IAM Policies
# ----------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role" "aws_backup_role" {
  count              = var.create && var.iam_role_arn == null ? 1 : 0
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

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ab_policy_attach" {
  count      = var.create && var.iam_role_arn == null ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.aws_backup_role[0].name
}

# Tag policy in case it needed
resource "aws_iam_policy" "ab_tag_policy" {

  count       = var.create && var.iam_role_arn == null ? 1 : 0
  description = "AWS Backup Tag policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Effect": "Allow",
        "Action": [
            "backup:TagResource",
            "backup:ListTags",
            "backup:UntagResource",
            "tag:GetResources"
        ],
        "Resource": "*"
    }
  ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "ab_tag_policy_attach" {
  count      = var.create && var.iam_role_arn == null ? 1 : 0
  policy_arn = aws_iam_policy.ab_tag_policy[0].arn
  role       = aws_iam_role.aws_backup_role[0].name
}


# Restores policy
resource "aws_iam_role_policy_attachment" "ab_restores_policy_attach" {
  count      = var.create && var.iam_role_arn == null ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
  role       = aws_iam_role.aws_backup_role[0].name
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

############################################################
# KMS key for fsx
############################################################
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
resource "aws_backup_vault" "default" {
  count       = var.create && var.vault_name != null ? 1 : 0
  name        = join("-", [local.module_prefix, "vault"])
  kms_key_arn = join("", aws_kms_key.default.*.arn)
  tags        = var.tags
}

############################################################
# Backup Plan
############################################################

resource "aws_backup_plan" "default" {
  count = var.create ? 1 : 0
  name  = join("-", [local.module_prefix, "plan"])

  # Rules
  dynamic "rule" {
    for_each = local.rules
    content {
      rule_name                = lookup(rule.value, "name", null)
      target_vault_name        = var.vault_name != null ? aws_backup_vault.default[0].name : lookup(rule.value, "target_vault_name", "Default")
      schedule                 = lookup(rule.value, "schedule", null)
      enable_continuous_backup = lookup(rule.value, "enable_continuous_backup", null)

      # Lifecycle
      dynamic "lifecycle" {
        for_each = length(lookup(rule.value, "lifecycle")) == 0 ? [] : [lookup(rule.value, "lifecycle", {})]
        content {
          cold_storage_after = lookup(lifecycle.value, "cold_storage_after", null)
          delete_after       = lookup(lifecycle.value, "delete_after", null)
        }
      }

      # Copy action
      dynamic "copy_action" {
        for_each = length(lookup(rule.value, "copy_action", {})) == 0 ? [] : [lookup(rule.value, "copy_action", {})]
        content {
          destination_vault_arn = lookup(copy_action.value, "destination_vault_arn", null)

          # Copy Action Lifecycle
          dynamic "lifecycle" {
            for_each = length(lookup(copy_action.value, "lifecycle", {})) == 0 ? [] : [lookup(copy_action.value, "lifecycle", {})]
            content {
              cold_storage_after = lookup(lifecycle.value, "cold_storage_after", null)
              delete_after       = lookup(lifecycle.value, "delete_after", null)
            }
          }
        }
      }

    }
  }
}

############################################################
# AWS Backup selection - resource arn
############################################################

resource "aws_backup_selection" "arn_resource_selection" {
  count        = var.create ? 1 : 0
  iam_role_arn = aws_iam_role.aws_backup_role[0].arn
  name         = join("-", [local.module_prefix, "resource"])
  plan_id      = aws_backup_plan.default[0].id

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
  value       = join("", aws_backup_vault.default.*.id)
}

output "vault_arn" {
  description = "The ARN of the vault"
  value       = join("", aws_backup_vault.default.*.arn)
}

output "backup_vault_recovery_points" {
  description = "Backup Vault recovery points"
  value       = join("", aws_backup_vault.default.*.recovery_points)
}

# Backup Plan
output "plan_id" {
  description = "The id of the backup plan"
  value       = join("", aws_backup_plan.default.*.id)
}

output "plan_arn" {
  description = "The ARN of the backup plan"
  value       = join("", aws_backup_plan.default.*.arn)
}

output "plan_version" {
  description = "Unique, randomly generated, Unicode, UTF-8 encoded string that serves as the version ID of the backup plan"
  value       = join("", aws_backup_plan.default.*.version)
}
