# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "scheduling_active" {
  type        = string
  default     = "Yes"
  description = "Activate or deactivate scheduling."
}

variable "scheduled_services" {
  type        = string
  default     = "Both"
  description = "Scheduled Services. Allowed values: EC2, RDS, Both"
}

variable "memory_size" {
  default     = "128"
  description = "Size of the Lambda function running the scheduler, increase size when processing large numbers of instances. Allowed values: 128, 384, 512, 640, 768, 896, 1024, 1152, 1280, 1408, 1536"
}

variable "use_cloud_watch_metrics" {
  type        = string
  default     = "Yes"
  description = "Collect instance scheduling data using CloudWatch metrics."
}

variable "log_retention_days" {
  default     = "30"
  description = "Retention days for scheduler logs."
}

variable "trace" {
  type        = string
  default     = "Yes"
  description = "Enable logging of detailed informtion in CloudWatch logs."
}

variable "child_account" {
  type        = list(string)
  default     = []
  description = "Child accounts to create destination points for"
}

variable "tag_name" {
  default     = "Schedule"
  type        = string
  description = "Name of tag to use for associating instance schedule schemas with service instances."
}

variable "default_timezone" {
  type        = string
  default     = "UTC"
  description = "Choose the default Time Zone. Default is 'UTC'"
}

variable "regions" {
  type        = string
  default     = "us-east-1"
  description = "Comma separated list of regions in which instances are scheduled, leave blank for current region only."
}

variable "cross_account_roles" {
  type        = string
  default     = ""
  description = "Comma separated list of ARN's for cross account access roles. These roles must be created in all checked accounts the scheduler to start and stop instances."
}

variable "started_tags" {
  type        = string
  default     = "ScheduleStatus=Started,ScheduleTimestamp={year}-{month}-{day} {hour}:{minute} {timezone}"
  description = "Comma separated list of tagname and values on the formt name=value,name=value,.. that are set on started instances"
}

variable "stopped_tags" {
  type        = string
  default     = "ScheduleStatus=Stopped,ScheduleTimestamp={year}-{month}-{day} {hour}:{minute} {timezone}"
  description = "Comma separated list of tagname and values on the formt name=value,name=value,.. that are set on stopped instances"
}

variable "scheduler_frequency" {
  type        = string
  default     = "5"
  description = "Scheduler running frequency in minutes. Allowed values: 1, 2, 5, 10, 15, 30, 60"
}

variable "schedule_lambda_account" {
  type        = string
  default     = "Yes"
  description = "Schedule instances in this account."
}

variable "send_anonymous_data" {
  type        = string
  default     = "No"
  description = "Send Anonymous Metrics Data."
}

variable "schedule_rds_clusters" {
  type        = string
  default     = "No"
  description = "Send Anonymous Metrics Data."
}

variable "create_rds_snapshot" {
  type        = string
  default     = "Yes"
  description = "Send Anonymous Metrics Data."
}

variable "is_standalone_scheduler" {
  default     = ""
  description = "Will deploy the master scheduler instead of the agent if set to true."
}

variable "accounts" {
  type    = list(string)
  default = [""]
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_cloudformation_stack" "aws_instance_scheduler" {
  count        = local.create_instance_scheduler
  name         = "aws-instance-scheduler"
  capabilities = ["CAPABILITY_IAM"]

  parameters = {
    TagName               = var.tag_name
    ScheduledServices     = var.scheduled_services
    SchedulingActive      = var.scheduling_active
    Regions               = var.regions
    DefaultTimezone       = var.default_timezone
    CrossAccountRoles     = local.aws_instance_scheduler_cross_account_roles
    ScheduleLambdaAccount = var.schedule_lambda_account
    SchedulerFrequency    = var.scheduler_frequency
    MemorySize            = var.memory_size
    ScheduleRdsClusters   = var.schedule_rds_clusters
    CreateRdsSnapshot     = var.create_rds_snapshot
    # Options
    UseCloudWatchMetrics = var.use_cloud_watch_metrics
    SendAnonymousData    = var.send_anonymous_data
    Trace                = var.trace
    # Other parameters
    LogRetentionDays = var.log_retention_days
    StartedTags      = var.started_tags
    StoppedTags      = var.stopped_tags
  }

  # template_body = file("${path.module}/cloudformation/aws-instance-scheduler.cft")
  template_url = "https://s3.amazonaws.com/solutions-reference/aws-instance-scheduler/latest/instance-scheduler.template"
}

resource "aws_cloudformation_stack" "schedule" {
  count        = local.create_instance_scheduler
  depends_on   = [aws_cloudformation_stack.aws_instance_scheduler]
  name         = "schedule"
  capabilities = ["CAPABILITY_IAM"]

  parameters = {
    ServiceTokenID = aws_cloudformation_stack.aws_instance_scheduler.0.outputs["ServiceInstanceScheduleServiceToken"]
  }

  template_body = file("${path.module}/cloudformation/schedule.cft")
}

module "instance_scheduler_agent" {
  source = "./instance-scheduler-agent"

  create            = local.create_instance_scheduler_agent
  master_account_id = var.master_account_id
}

locals {
  create_instance_scheduler       = var.create ? coalesce(var.is_standalone_scheduler, local.is_master) : 0
  create_instance_scheduler_agent = var.create && local.create_instance_scheduler != 1 ? local.is_child : 0
  aws_instance_scheduler_cross_account_roles = var.is_standalone_scheduler == 1 ? "" : coalesce(
    var.cross_account_roles,
    join(
      ",",
      formatlist(
        "arn:aws:iam::%s:role/aws-instance-scheduler-re-EC2SchedulerCrossAccount",
        var.accounts,
      ),
    ),
  )
}

