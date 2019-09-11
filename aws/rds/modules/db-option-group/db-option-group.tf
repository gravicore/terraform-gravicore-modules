# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "name" {
  default = "rds"
}

variable "create" {
  default = "true"
}

variable "aws_region" {
  default = "us-east-1"
}

variable terraform_module {
  default = "gravicore/terraform-gravicore-modules/aws/rds"
}

variable "namespace" {
  default = "grv"
}

variable "environment" {
  default = "shared"
}

variable "stage" {
  default = "dev"
}

variable "repository" {
  default = ""
}

variable "desc_prefix" {
  default = "Gravicore Module:"
}

variable "tags" {
  default = {}
}

variable "stage_prefix" {
  description = "Creates a unique name beginning with the specified prefix"
}

variable "module_prefix" {
  description = "Creates a unique name beginning with the specified prefix"
}

variable "identifier" {
  description = "The identifier of the resource"
  default     = "default rds"
}

variable "option_group_description" {
  description = "The description of the option group"
  default     = ""
}

variable "engine_name" {
  description = "Specifies the name of the engine that this option group should be associated with"
}

variable "major_engine_version" {
  description = "Specifies the major version of the engine that this option group should be associated with"
}

variable "options" {
  type        = "list"
  description = "A list of Options to apply"
  default     = []
}

variable "kms_key_id" {
  description = "The ARN for the KMS encryption key. If creating an encrypted replica, set this to the destination KMS ARN. If storage_encrypted is set to true and kms_key_id is not specified the default KMS key created in your account will be used"
  default     = ""
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_s3_bucket" "rds_backup_restore" {
  count  = "${var.create ? 1 : 0}"
  bucket = "${var.module_prefix}-rds"
  region = "${var.aws_region}"
  acl    = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "${var.kms_key_id}"
        sse_algorithm     = "aws:kms"
      }
    }
  }

  tags = "${var.tags}"
}

data "aws_iam_policy_document" "rds_backup_restore_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "rds_backup_restore" {
  count              = "${var.create ? 1 : 0}"
  name               = "${var.module_prefix}-${var.engine_name}-${replace(var.major_engine_version, ".", "-")}-backup-restore"
  description        = "Gravicore Module: Role to allow RDS to access S3 for DB backup and restore purposes"
  assume_role_policy = "${data.aws_iam_policy_document.rds_backup_restore_trust.json}"

  tags = "${var.tags}"
}

data "aws_iam_policy_document" "rds_backup_restore" {
  count = "${var.create ? 1 : 0}"

  statement {
    actions = [
      "kms:DescribeKey",
      "kms:GenerateDataKey",
      "kms:Encrypt",
      "kms:Decrypt",
    ]

    resources = ["${var.kms_key_id}"]
  }

  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
    ]

    resources = ["${aws_s3_bucket.rds_backup_restore.arn}"]
  }

  statement {
    actions = [
      "s3:GetObjectMetaData",
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListMultipartUploadParts",
      "s3:AbortMultipartUpload",
    ]

    resources = ["${aws_s3_bucket.rds_backup_restore.arn}/*"]
  }
}

resource "aws_iam_role_policy" "rds_backup_restore" {
  count = "${var.create ? 1 : 0}"
  name  = "rds-backup-restore-policy"
  role  = "${aws_iam_role.rds_backup_restore.id}"

  policy = "${data.aws_iam_policy_document.rds_backup_restore.json}"
}

resource "aws_db_option_group" "this" {
  count = "${var.create ? 1 : 0}"

  name                     = "${var.module_prefix}-${var.engine_name}-${replace(var.major_engine_version, ".", "-")}"
  option_group_description = "${var.option_group_description == "" ? format("Option group for %s", var.identifier) : var.option_group_description}"
  engine_name              = "${var.engine_name}"
  major_engine_version     = "${var.major_engine_version}"

  option = [
    {
      option_name = "SQLSERVER_BACKUP_RESTORE"

      option_settings = [
        {
          name  = "IAM_ROLE_ARN"
          value = "${aws_iam_role.rds_backup_restore.arn}"
        },
      ]
    },
  ]

  tags = "${var.tags}"

  lifecycle {
    create_before_destroy = true
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "this_db_option_group_id" {
  description = "The db option group id"
  value       = "${element(split(",", join(",", aws_db_option_group.this.*.id)), 0)}"
}

output "this_db_option_group_arn" {
  description = "The ARN of the db option group"
  value       = "${element(split(",", join(",", aws_db_option_group.this.*.arn)), 0)}"
}
