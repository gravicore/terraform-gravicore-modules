resource "aws_cloudformation_stack" "aws_instance_scheduler" {
  count        = "${local.creat_instance_scheduler}"
  name         = "aws-instance-scheduler"
  capabilities = ["CAPABILITY_IAM"]

  parameters {
    TagName               = "${var.TagName}"
    ScheduledServices     = "${var.ScheduledServices}"
    SchedulingActive      = "${var.SchedulingActive}"
    Regions               = "${var.Regions}"
    DefaultTimezone       = "${var.DefaultTimezone}"
    CrossAccountRoles     = "${local.aws_instance_scheduler_cross_account_roles}"
    ScheduleLambdaAccount = "${var.ScheduleLambdaAccount}"
    SchedulerFrequency    = "${var.SchedulerFrequency}"
    MemorySize            = "${var.MemorySize}"

    # Options
    UseCloudWatchMetrics = "${var.UseCloudWatchMetrics}"
    SendAnonymousData    = "${var.SendAnonymousData}"
    Trace                = "${var.Trace}"

    # Other parameters
    LogRetentionDays = "${var.LogRetentionDays}"
    StartedTags      = "${var.StartedTags}"
    StoppedTags      = "${var.StoppedTags}"
  }

  template_body = "${file("${path.module}/cloudformation/aws-instance-scheduler.cft")}"
}

resource "aws_cloudformation_stack" "schedule" {
  count        = "${local.creat_instance_scheduler}"
  depends_on   = ["aws_cloudformation_stack.aws_instance_scheduler"]
  name         = "schedule"
  capabilities = ["CAPABILITY_IAM"]

  parameters {
    ServiceTokenID = "${aws_cloudformation_stack.aws_instance_scheduler.outputs["ServiceInstanceScheduleServiceToken"]}"
  }

  template_body = "${file("${path.module}/cloudformation/schedule.cft")}"
}

module "instance_scheduler_agent" {
  source = "./instance-scheduler-agent"

  create            = "${local.creat_instance_scheduler_agent}"
  master_account_id = "${var.master_account_id}"
}

locals {
  creat_instance_scheduler                   = "${var.create == 1 ? local.is_master : 0 }"
  creat_instance_scheduler_agent             = "${var.create == 1 ? local.is_child : 0 }"
  aws_instance_scheduler_cross_account_roles = "${join(",",(formatlist("arn:aws:iam::%s:role/aws-instance-scheduler-re-EC2SchedulerCrossAccount", var.accounts)))}"
}
