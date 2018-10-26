variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "SchedulingActive" {
  type        = "string"
  default     = "yes"
  description = "Activate or deactivate scheduling."
}

variable "ScheduledServices" {
  type        = "string"
  default     = "Both"
  description = "Scheduled Services. Allowed values: EC2, RDS, Both"
}

variable "MemorySize" {
  default     = "128"
  description = "Size of the Lambda function running the scheduler, increase size when processing large numbers of instances. Allowed values: 128, 384, 512, 640, 768, 896, 1024, 1152, 1280, 1408, 1536"
}

variable "UseCloudWatchMetrics" {
  type        = "string"
  default     = "no"
  description = "Collect instance scheduling data using CloudWatch metrics."
}

variable "LogRetentionDays" {
  default     = "30"
  description = "Retention days for scheduler logs."
}

variable "Trace" {
  type        = "string"
  default     = "No"
  description = "Enable logging of detailed informtion in CloudWatch logs."
}

variable "child_account" {
  type        = "list"
  default     = []
  description = "Child accounts to create destination points for"
}

variable "TagName" {
  default     = "Schedule"
  type        = "string"
  description = "Name of tag to use for associating instance schedule schemas with service instances."
}

variable "DefaultTimezone" {
  type        = "string"
  default     = "UTC"
  description = "Choose the default Time Zone. Default is 'UTC'"
}

variable "Regions" {
  type        = "string"
  default     = ""
  description = "Comma separated list of regions in which instances are scheduled, leave blank for current region only."
}

variable "CrossAccountRoles" {
  type        = "string"
  default     = ""
  description = "Comma separated list of ARN's for cross account access roles. These roles must be created in all checked accounts the scheduler to start and stop instances."
}

variable "StartedTags" {
  type        = "string"
  description = "Comma separated list of tagname and values on the formt name=value,name=value,.. that are set on started instances"
}

variable "StoppedTags" {
  type        = "string"
  description = "Comma separated list of tagname and values on the formt name=value,name=value,.. that are set on stopped instances"
}

variable "SchedulerFrequency" {
  type        = "string"
  default     = "5"
  description = "Scheduler running frequency in minutes. Allowed values: 1, 2, 5, 10, 15, 30, 60"
}

variable "ScheduleLambdaAccount" {
  type        = "string"
  default     = "Yes"
  description = "Schedule instances in this account."
}

variable "SendAnonymousData" {
  type        = "string"
  default     = "Yes"
  description = "Send Anonymous Metrics Data."
}

variable "is_master" {
  description = "Passes through if account is master. 1 or 0"
  default     = "0"
}
