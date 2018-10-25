#KMS Keys
resource "aws_kms_key" "cloudwatch" {
  description         = "CloudWatch KMS Key"
  enable_key_rotation = "true"

  policy = <<POLICY
{
  "Version" : "2012-10-17",
  "Id" : "key-default-1",
  "Statement" : [ 
    {
      "Sid" : "Enable IAM User Permissions",
      "Effect" : "Allow",
      "Principal" : {
        "AWS" : "arn:aws:iam::${var.common_tags["account_id"]}:root"
      },
      "Action" : "kms:*",
      "Resource" : "*"
    },
    {
      "Effect": "Allow",
      "Principal": { 
        "Service": "logs.us-east-1.amazonaws.com"
      },
      "Action": [ 
        "kms:Encrypt*",
        "kms:Decrypt*",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*"
      ],
      "Resource": "*"
    }  
  ]
}
POLICY

  tags = "${merge(
    var.common_tags, 
    map(
      "Name" , "${local.name_prefix}-kms-cloudwatch",
      "resource", "kms-cloudwatch"
    )
  )}"
}

resource "aws_kms_alias" "cloudwatch" {
  name          = "alias/${var.common_tags["application"]}-kms-cloudwatch"
  target_key_id = "${aws_kms_key.cloudwatch.key_id}"
}
