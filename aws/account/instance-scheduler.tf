module "instance_scheduler" {
  source = "./modules/instance-scheduler"

  create                = "${var.create_instance_scheduler}"
  is_master             = "${local.is_master}"
  TagName               = "${var.TagName}"
  ScheduledServices     = "${var.ScheduledServices}"
  SchedulingActive      = "${var.SchedulingActive}"
  Regions               = "${var.Regions}"
  DefaultTimezone       = "${var.DefaultTimezone}"
  child_account         = "${var.accounts}"
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

module "instance_scheduler_agent" {
  source = "./modules/instance-scheduler-agent"

  create            = "${var.create_instance_scheduler}"
  master_account_id = "${var.master_account_id}"
  is_child          = "${local.is_child}"
}

variable "TagName" {
  description = "Name for tag key value"
  default     = "Schedule"
}

variable "ScheduledServices" {
  description = "Schedule EC2, RDS or Both"
  default     = "Both"
}

variable "SchedulingActive" {
  description = "Set schedules to be active."
  default     = "Yes"
}

variable "Regions" {
  description = "Regions to manage"
  default     = "us-east-1,us-east-2,us-west-1,us-west-2"
}

variable "DefaultTimezone" {
  description = "Default timezone"
  default     = "UTC"
}

variable "ScheduleLambdaAccount" {
  description = ""
  default     = "Yes"
}

variable "SchedulerFrequency" {
  description = "Frequency to run the scheduler in minutes"
  default     = "5"
}

variable "MemorySize" {
  description = "Max memory size for lambda function"
  default     = "128"
}

variable "UseCloudWatchMetrics" {
  description = "Whether to post to cloudwatch"
  default     = "Yes"
}

variable "SendAnonymousData" {
  description = ""
  default     = "No"
}

variable "Trace" {
  description = ""
  default     = "Yes"
}

variable "LogRetentionDays" {
  description = "Time to retain cloudwatch logs in days"
  default     = "30"
}

variable "StartedTags" {
  description = "Tag value to set when scheduler starts an instance"
  default     = "ScheduleStatus=Started,ScheduleTimestamp={year}-{month}-{day} {hour}:{minute} {timezone}"
}

variable "StoppedTags" {
  description = "Tag value to set when scheduler stops an instance"
  default     = "ScheduleStatus=Stopped,ScheduleTimestamp={year}-{month}-{day} {hour}:{minute} {timezone}"
}
