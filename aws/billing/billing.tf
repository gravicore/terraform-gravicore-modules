variable "s3_bucket_versioning" {
  description = "S3 bucket versioning enabled?"
  default     = false
}

resource "aws_s3_bucket" "billing" {
  count  = var.create ? 1 : 0
  bucket = local.module_prefix
  tags   = var.tags

  acl    = "private"

  versioning {
    enabled = var.s3_bucket_versioning
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

