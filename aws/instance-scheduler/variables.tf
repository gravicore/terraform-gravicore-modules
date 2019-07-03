variable "master_account_id" {}
variable "account_id" {}
variable "namespace" {}
variable "environment" {}
variable "stage" {}
variable "repository" {}

variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "master_account_assume_role_name" {
  default = "grv-deployment-service"
}

variable "account_assume_role_name" {
  default = "OrganizationAccountAccessRole"
}

variable "scheduling_active" {
  type        = "string"
  default     = "Yes"
  description = "Activate or deactivate scheduling."
}

variable "scheduled_services" {
  type        = "string"
  default     = "Both"
  description = "Scheduled Services. Allowed values: EC2, RDS, Both"
}

variable "memory_size" {
  default     = "128"
  description = "Size of the Lambda function running the scheduler, increase size when processing large numbers of instances. Allowed values: 128, 384, 512, 640, 768, 896, 1024, 1152, 1280, 1408, 1536"
}

variable "use_cloud_watch_metrics" {
  type        = "string"
  default     = "Yes"
  description = "Collect instance scheduling data using CloudWatch metrics."
}

variable "log_retention_days" {
  default     = "30"
  description = "Retention days for scheduler logs."
}

variable "trace" {
  type        = "string"
  default     = "Yes"
  description = "Enable logging of detailed informtion in CloudWatch logs."
}

variable "child_account" {
  type        = "list"
  default     = []
  description = "Child accounts to create destination points for"
}

variable "tag_name" {
  default     = "Schedule"
  type        = "string"
  description = "Name of tag to use for associating instance schedule schemas with service instances."
}

variable "default_timezone" {
  type        = "string"
  default     = "UTC"
  description = "Choose the default Time Zone. Default is 'UTC'"
}

variable "regions" {
  type        = "string"
  default     = "us-east-1"
  description = "Comma separated list of regions in which instances are scheduled, leave blank for current region only."
}

variable "cross_account_roles" {
  type        = "string"
  default     = ""
  description = "Comma separated list of ARN's for cross account access roles. These roles must be created in all checked accounts the scheduler to start and stop instances."
}

variable "started_tags" {
  type        = "string"
  default     = "ScheduleStatus=Started,ScheduleTimestamp={year}-{month}-{day} {hour}:{minute} {timezone}"
  description = "Comma separated list of tagname and values on the formt name=value,name=value,.. that are set on started instances"
}

variable "stopped_tags" {
  type        = "string"
  default     = "ScheduleStatus=Stopped,ScheduleTimestamp={year}-{month}-{day} {hour}:{minute} {timezone}"
  description = "Comma separated list of tagname and values on the formt name=value,name=value,.. that are set on stopped instances"
}

variable "scheduler_frequency" {
  type        = "string"
  default     = "5"
  description = "Scheduler running frequency in minutes. Allowed values: 1, 2, 5, 10, 15, 30, 60"
}

variable "schedule_lambda_account" {
  type        = "string"
  default     = "Yes"
  description = "Schedule instances in this account."
}

variable "send_anonymous_data" {
  type        = "string"
  default     = "No"
  description = "Send Anonymous Metrics Data."
}

variable "create" {
  default = true
}

variable "is_standalone_scheduler" {
  default     = ""
  description = "Will deploy the master scheduler instead of the agent if set to true."
}

variable "accounts" {
  type = "list"
}

variable "tags" {
  default = {}
}

variable "name" {
  default = "instance-scheduler"
}

variable terraform_module {
  default = "gravicore/terraform-gravicore-modules/aws/instance-scheduler"
}
