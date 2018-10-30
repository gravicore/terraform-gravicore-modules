# Public S3 bucket
resource "aws_s3_bucket" "public" {
  bucket = "${var.common_tags["application"]}-${var.common_tags["account_id"]}-public"
  acl    = "public-read"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  logging {
    target_bucket = "${aws_s3_bucket.log.id}"
    target_prefix = "prd/s3/public-bucket/"
  }

  tags = "${merge(
    var.common_tags, 
    map(
      "Name" , "${local.name_prefix}-s3-public",
      "resource", "s3-public"
    )
  )}"
}

# S3 Logging bucket
resource "aws_s3_bucket" "log" {
  bucket = "${var.common_tags["application"]}-logs-${var.common_tags["account_id"]}"
  acl    = "log-delivery-write"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  #  policy = "${file("../../modules/policies/s3-log.txt")}"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::${var.common_tags["application"]}-logs-${var.common_tags["account_id"]}"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::${var.common_tags["application"]}-logs-${var.common_tags["account_id"]}/*",
            "Condition": {
              "StringEquals": {
                "s3:x-amz-acl": "bucket-owner-full-control"
              }
            }
        },
        {
          "Sid": "ElbUsEast1",
          "Effect": "Allow",
          "Principal": {
            "AWS": [
              "127311923021"
            ]
          },
          "Action": "s3:PutObject",
          "Resource": "arn:aws:s3:::${var.common_tags["application"]}-logs-${var.common_tags["account_id"]}/*"
        }
    ]
}
POLICY
  tags = "${merge(
    var.common_tags, 
    map(
      "Name" , "${local.name_prefix}-s3-log",
      "resource", "s3-log"
    )
  )}"
}
