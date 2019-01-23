data "aws_iam_policy_document" "SchedulerCrossAccountPolicy" {
  statement {
    actions = [
      "ec2:DescribeInstances",
      "ec2:StartInstances",
      "ec2:StopInstances",
      "ec2:ModifyInstanceAttribute",
      "ec2:CreateTags",
      "ec2:DeleteTags",
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "rds:DescribeDBInstances",
      "rds:DescribeDBSnapshots",
      "rds:StartDBInstance",
      "rds:StopDBInstance",
      "rds:AddTagsToResource",
      "rds:RemoveTagsFromResource",
      "rds:DeleteDBSnapshot",
    ]

    resources = ["*"]
  }

  statement {
    actions   = ["tag:GetResources"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "EC2InstanceSchedulerRemote" {
  count  = "${local.create_instance_scheduler}"
  name   = "EC2InstanceSchedulerRemote"
  role   = "${aws_iam_role.aws-instance-scheduler-re-EC2SchedulerCrossAccount.id}"
  policy = "${data.aws_iam_policy_document.SchedulerCrossAccountPolicy.json}"
}

data "aws_iam_policy_document" "lambda-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.master_account_id}:root"]
    }
  }
}

resource "aws_iam_role" "aws-instance-scheduler-re-EC2SchedulerCrossAccount" {
  count              = "${local.create_instance_scheduler}"
  name               = "aws-instance-scheduler-re-EC2SchedulerCrossAccount"
  assume_role_policy = "${data.aws_iam_policy_document.lambda-assume-role-policy.json}"
}

locals {
  create_instance_scheduler = "${var.create == 1 ? var.is_child : 0 }"
}
