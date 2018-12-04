data "aws_iam_policy_document" "rds_ds_access" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "rds_ds_access" {
  name               = "rds-ds-access-role"
  assume_role_policy = "${data.aws_iam_policy_document.rds_ds_access.json}"
}

resource "aws_iam_role_policy_attachment" "rds_ds_access" {
  role       = "${aws_iam_role.rds_ds_access.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSDirectoryServiceAccess"
}

# data "aws_iam_policy_document" "rds_backup_restore" {
#   statement {
#     actions = ["sts:AssumeRole"]


#     principals {
#       type        = "Service"
#       identifiers = ["rds.amazonaws.com"]
#     }
#   }
# }

