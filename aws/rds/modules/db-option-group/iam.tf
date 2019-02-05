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
  name               = "${var.name_prefix}-${var.engine_name}-${replace(var.major_engine_version, ".", "-")}-backup-restore"
  description        = "Gravicore Module: Role to allow RDS to access S3 for DB backup and restore purposes"
  assume_role_policy = "${data.aws_iam_policy_document.rds_backup_restore_trust.json}"

  tags = "${var.tags}"
}

data "aws_iam_policy_document" "rds_backup_restore" {
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

# resource "aws_iam_policy" "rds_backup_restore" {
#   name   = "rds-backup-restore-policy"
#   policy = "${data.aws_iam_policy_document.rds_backup_restore}"
# }

resource "aws_iam_role_policy" "rds_backup_restore" {
  count = "${var.create ? 1 : 0}"
  name  = "rds-backup-restore-policy"
  role  = "${aws_iam_role.rds_backup_restore.id}"

  policy = "${data.aws_iam_policy_document.rds_backup_restore.json}"
}
