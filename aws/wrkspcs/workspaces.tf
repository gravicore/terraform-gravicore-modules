# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "ip_group_ids" {
  type        = list(string)
  default     = []
  description = "(Optional) The identifiers of the IP access control groups associated with the directory"
}

variable "bundle_id_default" {
  description = "(Required) The ID of the bundle for the WorkSpace"
  type        = string
  default     = ""
}

variable "change_compute_type" {
  type        = bool
  default     = false
  description = "(Optional) Whether WorkSpaces directory users can change the compute type (bundle) for their workspace"
}

variable "increase_volume_size" {
  type        = bool
  default     = false
  description = "(Optional) Whether WorkSpaces directory users can increase the volume size of the drives on their workspace"
}

variable "rebuild_workspace" {
  type        = bool
  default     = false
  description = "(Optional) Whether WorkSpaces directory users can rebuild the operating system of a workspace to its original state"
}

variable "restart_workspace" {
  type        = bool
  default     = true
  description = "(Optional) Whether WorkSpaces directory users can restart their workspace"
}

variable "switch_running_mode" {
  type        = bool
  default     = false
  description = "(Optional) Whether WorkSpaces directory users can switch the running mode of their workspace"
}

variable "allow_device_type_android" {
  type        = bool
  default     = true
  description = "(Optional) Indicates whether users can use Android devices to access their WorkSpaces."
}

variable "allow_device_type_chromeos" {
  type        = bool
  default     = true
  description = "(Optional) Indicates whether users can use Chromebooks to access their WorkSpaces."
}

variable "allow_device_type_ios" {
  type        = bool
  default     = true
  description = "(Optional) Indicates whether users can use iOS devices to access their WorkSpaces."
}

variable "allow_device_type_linux" {
  type        = bool
  default     = true
  description = "(Optional) Indicates whether users can use Linux clients to access their WorkSpaces."
}

variable "allow_device_type_osx" {
  type        = bool
  default     = true
  description = "(Optional) Indicates whether users can use macOS clients to access their WorkSpaces."
}

variable "allow_device_type_web" {
  type        = bool
  default     = false
  description = "(Optional) Indicates whether users can access their WorkSpaces through a web browser."
}

variable "allow_device_type_windows" {
  type        = bool
  default     = true
  description = "(Optional) Indicates whether users can use Windows clients to access their WorkSpaces."
}

variable "allow_device_type_zeroclient" {
  type        = bool
  default     = true
  description = "(Optional) Indicates whether users can use zero client devices to access their WorkSpaces."
}

variable "default_ou" {
  type        = string
  default     = ""
  description = "(Optional) The default organizational unit (OU) for your WorkSpace directories. Should conform 'OU=<value>,DC=<value>,...,DC=<value>' pattern"
}

variable "enable_internet_access" {
  type        = bool
  default     = null
  description = "(Optional) Indicates whether internet access is enabled for your WorkSpaces"
}

variable "enable_maintenance_mode" {
  type        = bool
  default     = null
  description = "(Optional) Indicates whether maintenance mode is enabled for your WorkSpaces. For more information, see https://docs.aws.amazon.com/workspaces/latest/adminguide/workspace-maintenance.html"
}

variable "user_enabled_as_local_administrator" {
  type        = bool
  default     = false
  description = "(Optional) Indicates whether users are local administrators of their WorkSpaces"
}

variable "root_volume_encryption_enabled_default" {
  description = "(Optional) Indicates whether the data stored on the root volume is encrypted"
  type        = bool
  default     = false
}

variable "user_volume_encryption_enabled_default" {
  description = "(Optional) Indicates whether the data stored on the user volume is encrypted"
  type        = bool
  default     = false
}

variable "volume_encryption_key_default" {
  description = "(Optional) The symmetric AWS KMS customer master key (CMK) used to encrypt data stored on your WorkSpace. Amazon WorkSpaces does not support asymmetric CMKs"
  type        = string
  default     = null
}

variable "compute_type_name_default" {
  description = "(Optional) The compute type. For more information, see Amazon WorkSpaces Bundles. Valid values are VALUE, STANDARD, PERFORMANCE, POWER, GRAPHICS, POWERPRO and GRAPHICSPRO"
  type        = string
  default     = "VALUE"
}

variable "user_volume_size_gib_default" {
  description = "(Optional) The size of the user storage"
  type        = number
  default     = 10
}

variable "root_volume_size_gib_default" {
  description = "(Optional) The size of the root volume"
  type        = number
  default     = 80
}

variable "running_mode_default" {
  description = "(Optional) The running mode. For more information, see Manage the WorkSpace Running Mode. Valid values are AUTO_STOP and ALWAYS_ON"
  type        = string
  default     = "AUTO_STOP"
}

variable "running_mode_auto_stop_timeout_in_minutes_default" {
  description = "(Optional) The running mode. For more information, see Manage the WorkSpace Running Mode. Valid values are AUTO_STOP and ALWAYS_ON"
  type        = number
  default     = 60
}

variable "email_domain_default" {
  description = "The email domain to append to the username to generate the email address"
  type        = string
  default     = ""
}

variable "ws_users" {
  description = "(Required) The user name of the user for the WorkSpace. This user name must exist in the directory for the WorkSpace"
  type        = map(any)
  default     = {}
}

variable "ws_directory_id" {
  description = "(Required) The ID of the directory for the WorkSpace"
  type        = string
  default     = ""
}

variable "create_ws_default_role" {
  description = "(Optional) If true create default IAM role"
  type        = bool
  default     = true
}

variable "create_admin_workspace" {
  description = "(Optional) If true create admin workspace"
  type        = bool
  default     = false
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

data "aws_subnet" "default" {
  count = var.create ? 1 : 0
  id    = var.subnet_ids[0]
}

resource "aws_security_group" "default" {
  count       = var.create ? 1 : 0
  name        = local.module_prefix
  tags        = local.tags
  description = join(" ", [var.desc_prefix, local.module_prefix, "security group"])

  vpc_id = concat(data.aws_subnet.default.*.vpc_id, [""])[0]
}

resource "aws_iam_role" "workspaces_default" {
  count       = var.create && var.create_ws_default_role ? 1 : 0
  name        = "workspaces_DefaultRole"
  tags        = local.tags
  description = join(" ", [var.desc_prefix, "default IAM role for workspaces"])

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "workspaces.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "workspaces_default_service_access" {
  count      = var.create && var.create_ws_default_role ? 1 : 0
  role       = concat(aws_iam_role.workspaces_default.*.name, [""])[0]
  policy_arn = "arn:aws:iam::aws:policy/AmazonWorkSpacesServiceAccess"
}

resource "aws_iam_role_policy_attachment" "workspaces_default_self_service_access" {
  count      = var.create && var.create_ws_default_role ? 1 : 0
  role       = concat(aws_iam_role.workspaces_default.*.name, [""])[0]
  policy_arn = "arn:aws:iam::aws:policy/AmazonWorkSpacesSelfServiceAccess"
}

data "aws_workspaces_bundle" "default" {
  count = var.create && var.bundle_id_default == "" ? 1 : 0
  owner = "AMAZON"
  name  = "Standard with Windows 10 (Server 2019 based)"
}

resource "aws_workspaces_directory" "default" {
  count = var.create ? 1 : 0
  tags  = local.tags

  directory_id = var.directory_id != "" ? var.directory_id : module.ds.id
  subnet_ids   = var.subnet_ids
  ip_group_ids = concat(var.ip_group_ids, aws_workspaces_ip_group.default.*.id)

  self_service_permissions {
    change_compute_type  = var.change_compute_type
    increase_volume_size = var.increase_volume_size
    rebuild_workspace    = var.rebuild_workspace
    restart_workspace    = var.restart_workspace
    switch_running_mode  = var.switch_running_mode
  }

  workspace_access_properties {
    device_type_android    = var.allow_device_type_android ? "ALLOW" : "DENY"
    device_type_chromeos   = var.allow_device_type_chromeos ? "ALLOW" : "DENY"
    device_type_ios        = var.allow_device_type_ios ? "ALLOW" : "DENY"
    device_type_linux      = var.allow_device_type_linux ? "ALLOW" : "DENY"
    device_type_osx        = var.allow_device_type_osx ? "ALLOW" : "DENY"
    device_type_web        = var.allow_device_type_web ? "ALLOW" : "DENY"
    device_type_windows    = var.allow_device_type_windows ? "ALLOW" : "DENY"
    device_type_zeroclient = var.allow_device_type_zeroclient ? "ALLOW" : "DENY"
  }

  workspace_creation_properties {
    custom_security_group_id            = concat(aws_security_group.default.*.id, [""])[0]
    default_ou                          = var.default_ou
    enable_internet_access              = var.enable_internet_access
    enable_maintenance_mode             = var.enable_maintenance_mode
    user_enabled_as_local_administrator = var.user_enabled_as_local_administrator
  }
}

resource "aws_workspaces_workspace" "default" {
  for_each = var.create ? var.ws_users : {}
  tags     = merge(local.tags, { "user_email" = join("@", [each.key, lookup(each.value, "email_domain", var.email_domain_default)]) })

  directory_id = var.directory_id != "" ? var.directory_id : module.ds.id
  bundle_id    = lookup(each.value, "bundle_id", var.bundle_id_default == "" ? concat(data.aws_workspaces_bundle.default.*.bundle_id, [""])[0] : var.bundle_id_default)
  user_name    = each.key

  root_volume_encryption_enabled = lookup(each.value, "root_volume_encryption_enabled", var.root_volume_encryption_enabled_default)
  user_volume_encryption_enabled = lookup(each.value, "user_volume_encryption_enabled", var.user_volume_encryption_enabled_default)
  volume_encryption_key          = lookup(each.value, "volume_encryption_key", var.volume_encryption_key_default)

  workspace_properties {
    compute_type_name                         = lookup(each.value, "compute_type_name", var.compute_type_name_default)
    user_volume_size_gib                      = lookup(each.value, "user_volume_size_gib", var.user_volume_size_gib_default)
    root_volume_size_gib                      = lookup(each.value, "root_volume_size_gib", var.root_volume_size_gib_default)
    running_mode                              = lookup(each.value, "running_mode", var.running_mode_default)
    running_mode_auto_stop_timeout_in_minutes = lookup(each.value, "running_mode_auto_stop_timeout_in_minutes", var.running_mode_auto_stop_timeout_in_minutes_default)
  }
  depends_on = [
    aws_workspaces_directory.default,
  ]
}

resource "aws_workspaces_workspace" "admin" {
  count = var.create && var.create_admin_workspace ? 1 : 0
  tags  = local.tags

  directory_id = var.directory_id != "" ? var.directory_id : module.ds.id
  bundle_id    = concat(data.aws_workspaces_bundle.default.*.bundle_id, [""])[0]
  user_name    = "Administrator"

  root_volume_encryption_enabled = var.root_volume_encryption_enabled_default
  user_volume_encryption_enabled = var.user_volume_encryption_enabled_default
  volume_encryption_key          = var.volume_encryption_key_default

  workspace_properties {
    compute_type_name                         = var.compute_type_name_default
    user_volume_size_gib                      = var.user_volume_size_gib_default
    root_volume_size_gib                      = var.root_volume_size_gib_default
    running_mode                              = var.running_mode_default
    running_mode_auto_stop_timeout_in_minutes = var.running_mode_auto_stop_timeout_in_minutes_default
  }
  depends_on = [
    aws_workspaces_directory.default,
  ]
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "directory_id" {
  description = "The directory ID"
  value       = concat(aws_workspaces_directory.default.*.directory_id, [""])[0]
}
