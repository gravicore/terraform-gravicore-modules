resource "aws_cloudformation_stack" "aws_instance_scheduler" {
  count        = "${local.create_instance_scheduler}"
  name         = "aws-instance-scheduler"
  capabilities = ["CAPABILITY_IAM"]

  parameters {
    TagName               = "${var.tag_name}"
    ScheduledServices     = "${var.scheduled_services}"
    SchedulingActive      = "${var.scheduling_active}"
    Regions               = "${var.regions}"
    DefaultTimezone       = "${var.default_timezone}"
    CrossAccountRoles     = "${local.aws_instance_scheduler_cross_account_roles}"
    ScheduleLambdaAccount = "${var.schedule_lambda_account}"
    SchedulerFrequency    = "${var.scheduler_frequency}"
    MemorySize            = "${var.memory_size}"

    # Options
    UseCloudWatchMetrics = "${var.use_cloud_watch_metrics}"
    SendAnonymousData    = "${var.send_anonymous_data}"
    Trace                = "${var.trace}"

    # Other parameters
    LogRetentionDays = "${var.log_retention_days}"
    StartedTags      = "${var.started_tags}"
    StoppedTags      = "${var.stopped_tags}"
  }

  template_body = "${file("${path.module}/cloudformation/aws-instance-scheduler.cft")}"
}

resource "aws_cloudformation_stack" "schedule" {
  count        = "${local.create_instance_scheduler}"
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

  create            = "${local.create_instance_scheduler_agent}"
  master_account_id = "${var.master_account_id}"
}

locals {
  create_instance_scheduler                  = "${var.create == 1 ? coalesce(var.is_standalone_scheduler, local.is_master) : 0}"
  create_instance_scheduler_agent            = "${var.create == 1 ? local.create_instance_scheduler == 1 ? 0 : local.is_child : 0}"
  aws_instance_scheduler_cross_account_roles = "${var.is_standalone_scheduler == 1 ? "" : coalesce(var.cross_account_roles, join(",",(formatlist("arn:aws:iam::%s:role/aws-instance-scheduler-re-EC2SchedulerCrossAccount", var.accounts)))) }"
}
