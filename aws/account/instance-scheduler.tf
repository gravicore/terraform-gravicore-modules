module "instance_scheduler" {
  source                = "git::https://github.com/gravicore/terraform-gravicore-modules.git//aws/account/modules/instance-scheduler?ref=0.5.0"
  create                = "${var.creat_instance_scheduler}"
  is_master             = "${local.is_master}"
  TagName               = "Schedule"
  ScheduledServices     = "Both"
  SchedulingActive      = "Yes"
  Regions               = "us-east-1,us-east-2,us-west-1,us-west-2"
  DefaultTimezone       = "UTC"
  child_account         = "${var.accounts}"
  ScheduleLambdaAccount = "Yes"
  SchedulerFrequency    = "5"
  MemorySize            = "128"

  # Options
  UseCloudWatchMetrics = "Yes"
  SendAnonymousData    = "No"
  Trace                = "Yes"

  # Other parameters
  LogRetentionDays = "30"
  StartedTags      = "ScheduleStatus=Started,ScheduleTimestamp={year}-{month}-{day} {hour}:{minute} {timezone}"
  StoppedTags      = "ScheduleStatus=Stopped,ScheduleTimestamp={year}-{month}-{day} {hour}:{minute} {timezone}"
}

module "instance_scheduler_agent" {
  source            = "git::https://github.com/gravicore/terraform-gravicore-modules.git//aws/account/modules/instance-scheduler-agent?ref=0.5.0"
  create            = "${var.creat_instance_scheduler}"
  master_account_id = "${var.master_account_id}"
  is_child          = "${local.is_child}"
}

# locals {
#   is_master = "${var.master_account_id == var.account_id ? 1 : 0 }"
#   is_child  = "${var.master_account_id != var.account_id ? 1 : 0 }"
# }

