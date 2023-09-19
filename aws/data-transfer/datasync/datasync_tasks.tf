# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "datasync_tasks" {
  description = "Tasks for DataSync"
  type        = map(any)
  default     = {}
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "Specifies the number of days you want to retain log events in the specified log group"
  type        = string
  default     = 30
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_datasync_task" "datasync" {
  for_each = var.create && var.datasync_agent_id != null && length(var.datasync_tasks) > 0 ? var.datasync_tasks : {}
  name     = join("-", [local.module_prefix, each.key])
  tags     = local.tags

  source_location_arn      = local.datasync_locations_arns[each.value.source_id]
  destination_location_arn = local.datasync_locations_arns[each.value.destination_id]
  cloudwatch_log_group_arn = replace(aws_cloudwatch_log_group.datasync[0].arn, ":*", "")
  options {
    # V (Optional) A file metadata that shows the last time a file was accessed (that is when the file was read or written
    # to). If set to BEST_EFFORT, the DataSync Task attempts to preserve the original (that is, the version before sync
    # PREPARING phase) atime attribute on all source files. Valid values: BEST_EFFORT, NONE. Default: BEST_EFFORT.
    atime = lookup(each.value, "atime", null)
    # (Optional) Limits the bandwidth utilized. For example, to set a maximum of 1 MB, set this value to 1048576. Value
    # values: -1 or greater. Default: -1 (unlimited).
    bytes_per_second = lookup(each.value, "bytes_per_second", null)
    # (Optional) Group identifier of the file's owners. Valid values: BOTH, INT_VALUE, NAME, NONE. Default: INT_VALUE
    # (preserve integer value of the ID).
    gid = lookup(each.value, "gid", null)
    #  (Optional) A file metadata that indicates the last time a file was modified (written to) before the sync PREPARING
    # phase. Value values: NONE, PRESERVE. Default: PRESERVE.
    mtime = lookup(each.value, "atime", null) == "BEST_EFFORT" ? "PRESERVE" : lookup(each.value, "atime", null) == "NONE" ? "NONE" : null
    # (Optional) Determines which users or groups can access a file for a specific purpose such as reading, writing, or
    # execution of the file. Valid values: NONE, PRESERVE. Default: PRESERVE.
    posix_permissions = lookup(each.value, "posix_permissions", null)
    # (Optional) Whether files deleted in the source should be removed or preserved in the destination file system. Valid
    # values: PRESERVE, REMOVE. Default: PRESERVE.
    preserve_deleted_files = lookup(each.value, "preserve_deleted_files", null)
    # (Optional) Whether the DataSync Task should preserve the metadata of block and character devices in the source
    # files system, and recreate the files with that device name and metadata on the destination. The DataSync Task can’t
    # sync the actual contents of such devices, because many of the devices are non-terminal and don’t return an end of
    # file (EOF) marker. Valid values: NONE, PRESERVE. Default: NONE (ignore special devices).
    preserve_devices = lookup(each.value, "preserve_devices", null)
    # (Optional) User identifier of the file's owners. Valid values: BOTH, INT_VALUE, NAME, NONE. Default: INT_VALUE
    # (preserve integer value of the ID).
    uid = lookup(each.value, "uid", null)
    # (Optional) Whether a data integrity verification should be performed at the end of a task execution after all data
    # and metadata have been transferred. Valid values: NONE, POINT_IN_TIME_CONSISTENT. Default: POINT_IN_TIME_CONSISTENT.
    # TERRAFORM MISSING verify_mode = "ONLY_FILES_TRANSFERRED"
    verify_mode = lookup(each.value, "verify_mode", null)
  }

  lifecycle {
    ignore_changes = [
      options[0].verify_mode,
    ]
  }

  timeouts {
    create = "2m"
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# Outputs
# ----------------------------------------------------------------------------------------------------------------------

output "datasync_cloudwatch_log_group_arn" {
  description = "ARN specifying the CloudWatch log group"
  value       = var.create && var.datasync_agent_id != null ? aws_cloudwatch_log_group.datasync[0].arn : null
}

output "datasync_tasks" {
  description = "Tasks for DataSync"
  value       = var.create && var.datasync_agent_id != null && length(var.datasync_tasks) > 0 ? aws_datasync_task.datasync : null
}
