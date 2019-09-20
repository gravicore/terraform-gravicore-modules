# S3 - Terraform remote state bucket
resource "aws_s3_bucket" "remote-state" {
  bucket = "${var.name_prefix}-remote-state"
  acl    = "private"

  lifecycle {
    prevent_destroy = false
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  versioning {
    enabled = true
  }

  tags = merge(
    var.tags,
    {
      "Name"     = "${var.name_prefix}-remote-state"
      "Resource" = "aws_s3_bucket"
    },
  )
}

# DynamoDB - Terraform state lock table
resource "aws_dynamodb_table" "remote-state-lock" {
  name           = "${var.name_prefix}-remote-state-lock"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(
    var.tags,
    {
      "Name"     = "${var.name_prefix}-remote-state-lock"
      "Resource" = "aws_dynamodb_table"
    },
  )
}

