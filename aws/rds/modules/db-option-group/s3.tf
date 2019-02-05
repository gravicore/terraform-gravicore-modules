resource "aws_s3_bucket" "rds_backup_restore" {
  count  = "${var.create ? 1 : 0}"
  bucket = "${var.name_prefix}-rds"
  region = "${var.aws_region}"
  acl    = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "arn:aws:kms:us-east-1:119494328224:key/2209e5e5-acfd-4be5-b39d-abcaf5265f49"
        sse_algorithm     = "aws:kms"
      }
    }
  }

  tags = "${var.tags}"
}
