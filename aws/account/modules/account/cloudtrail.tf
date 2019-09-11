#CloudTrail
resource "aws_cloudtrail" "this" {
  name                  = "${var.common_tags["application"]}-cloudtrail-${var.common_tags["account_id"]}"
  s3_bucket_name        = "${var.common_tags["application"]}-logs-${var.common_tags["account_id"]}"
  s3_key_prefix         = "${var.common_tags["component"]}/cloudtrail/"
  is_multi_region_trail = "true"

  tags = merge(
    var.common_tags,
    {
      "Name"     = "${local.name_prefix}-cloudtrail"
      "resource" = "cloudtrail"
    },
  )
}

