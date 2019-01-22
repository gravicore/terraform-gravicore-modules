locals {
  aws_instance_scheduler_cross_account_roles = "${join(",",(formatlist("arn:aws:iam::%s:role/aws-instance-scheduler-re-EC2SchedulerCrossAccount", var.child_account)))}"
}

resource "aws_cloudformation_stack" "aws_instance_scheduler" {
  count        = "${var.is_master}"
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

<<<<<<< HEAD
resource "aws_cloudformation_stack" "schedule" {
  count        = "${var.is_master}"
  depends_on   = ["aws_cloudformation_stack.aws_instance_scheduler"]
  name         = "schedule"
=======
resource "aws_cloudformation_stack" "aws_instance_scheduler_schedules" {
  count        = "${var.is_master}"
  depends_on   = ["aws_cloudformation_stack.aws_instance_scheduler"]
  name         = "aws-instance-scheduler-schedules"
>>>>>>> master
  capabilities = ["CAPABILITY_IAM"]

  parameters {
    ServiceTokenID = "${aws_cloudformation_stack.aws_instance_scheduler.outputs["ServiceInstanceScheduleServiceToken"]}"
  }

<<<<<<< HEAD
  template_body = "${file("${path.module}/cloudformation/schedule.cft")}"
=======
  template_body = "${file("${path.module}/cloudformation/aws-instance-scheduler-schedules.cft")}"
>>>>>>> master
}
