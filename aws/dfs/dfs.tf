# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE / AMI definition
# ----------------------------------------------------------------------------------------------------------------------

variable "vpc_id" {
  type = string
}

variable "instances" {
  description = "Map of DFS instance definitions. Each instance may define subnet_id, private_ip, and an optional name."
  type = map(object({
    name                        = optional(string)
    subnet_id                   = string
    private_ip                  = optional(string)
    ami_name                    = optional(string, "Windows_Server-2025-English-Full-Base-*") ##"Windows_Server-2025-English-Full-Base-*"
    instance_type               = optional(string, "t3.medium")                               ##"t3.medium"
    monitoring                  = optional(bool, false)
    associate_public_ip_address = optional(bool, false)           ##"If true, the launched EC2 instance will have associated public IP address"
    ipv6_address_count          = optional(number, null)          ## A number of IPv6 addresses to associate with the primary network interface. Amazon EC2 chooses the IPv6 addresses from the range of your subnet.
    ipv6_addresses              = optional(list(string), null)    ## Specify one or more IPv6 addresses from the range of the subnet to associate with the primary network interface
    ebs_optimized               = optional(bool, false)           ## If true, the launched EC2 instance will be EBS-optimized
    ebs_block_device            = optional(list(map(string)), []) ## Additional EBS block devices to attach to the instance
    root_block_device           = optional(list(map(string)), []) ## Customize details about the root block device of the instance. See Block Devices below for details
    ephemeral_block_device      = optional(list(map(string)), []) ## Customize details about the ephemeral (also known as instance store) block devices of the instance. See Block Devices below for details
  }))
  default = {}
}

# DFS Namespace machine

variable "vm_dfs_disk_size" {
  description = "EC2 root disk size"
  default     = "60"
  type        = string
}

variable "placement_group" {
  description = "The Placement Group to start the instance in"
  type        = string
  default     = ""
}

variable "get_password_data" {
  description = "If true, wait for password data to become available and retrieve it."
  type        = bool
  default     = false
}

variable "tenancy" {
  description = "The tenancy of the instance (if the instance is running in a VPC). Available values: default, dedicated, host."
  type        = string
  default     = "default"
}

variable "disable_api_termination" {
  description = "If true, enables EC2 Instance Termination Protection"
  type        = bool
  default     = false
}

variable "instance_initiated_shutdown_behavior" {
  description = "Shutdown behavior for the instance" # https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/terminating-instances.html#Using_ChangingInstanceInitiatedShutdownBehavior
  type        = string
  default     = ""
}

variable "key_name" {
  description = "The key name to use for the instance"
  type        = string
}

variable "vpc_security_group_ids" {
  description = "A list of security group IDs to associate with"
  type        = list(string)
  default     = null
}

variable "source_dest_check" {
  description = "Controls if traffic is routed to the instance when the destination address does not match the instance. Used for NAT or VPNs."
  type        = bool
  default     = true
}

variable "user_data_base64" {
  description = "Can be used instead of user_data to pass base64-encoded binary data directly. Use this instead of user_data whenever the value is not a valid UTF-8 string. For example, gzip-encoded user data must be base64-encoded and passed via this argument to avoid corruption."
  type        = string
  default     = null
}

variable "iam_instance_profile" {
  description = "The IAM Instance Profile to launch the instance with. Specified as the name of the Instance Profile."
  type        = string
  default     = ""
}

variable "network_interface" {
  description = "Customize network interfaces to be attached at instance boot time"
  type        = list(map(string))
  default     = []
}

variable "metadata_options" {
  description = "Customize the metadata options of the instance"
  type        = map(string)
  default     = {}
}

data "aws_ami" "windows" {
  for_each    = var.create ? var.instances : {}
  most_recent = true
  filter {
    name   = "name"
    values = [lookup(each.value, "ami_name", "Windows_Server-2016-English-Full-Base-*")]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["801119661308"] # Canonical
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

#########################################################
# Security group for DFS Namespace. All traffic from my IP.
#########################################################

variable "ingress_cidrs" {
  type        = list(string)
  default     = [""]
  description = "description"
}

variable "tcp_allowed_ports" {
  type = list(object({
    from_port = number
    to_port   = number
  }))
}

variable "udp_allowed_ports" {
  type = list(object({
    from_port = number
    to_port   = number
  }))
}

# ----------------------------------------------
####### Security Group 
# ----------------------------------------------

resource "aws_security_group" "default" {
  count       = var.create ? 1 : 0
  name        = local.module_prefix
  description = "common FSx ports"
  vpc_id      = var.vpc_id
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "Egress"
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }
  tags = local.tags
}

resource "aws_security_group_rule" "allow_ingress_cidr_tcp" {
  for_each          = { for port in var.tcp_allowed_ports : port.from_port => port }
  security_group_id = concat(aws_security_group.default.*.id, [""])[0]
  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = "tcp"
  cidr_blocks       = var.ingress_cidrs
}

resource "aws_security_group_rule" "allow_ingress_cidr_icmp" {
  count             = var.create ? 1 : 0
  security_group_id = concat(aws_security_group.default.*.id, [""])[0]
  type              = "ingress"
  from_port         = "-1"
  to_port           = "-1"
  protocol          = "icmp"
  cidr_blocks       = var.ingress_cidrs
}

resource "aws_security_group_rule" "allow_ingress_cidr_udp" {
  for_each          = { for port in var.udp_allowed_ports : port.from_port => port }
  security_group_id = concat(aws_security_group.default.*.id, [""])[0]
  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = "udp"
  cidr_blocks       = var.ingress_cidrs
}

#########################################################
# IAM policies for SSM
#########################################################
resource "aws_iam_role" "ec2_role" {
  count = var.create ? 1 : 0
  name  = join("-", [local.module_prefix, "ec2-ssm-attach"])

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ec2.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_instance_profile" "ec2_ad_instance_profile" {
  count = var.create ? 1 : 0
  name  = join("-", [local.module_prefix, "ec2-instance-profile"])
  role  = concat(aws_iam_role.ec2_role.*.name, [""])[0]
}

resource "aws_iam_role_policy_attachment" "ec2-ad-role-policy-attach" {
  count      = var.create ? 1 : 0
  role       = concat(aws_iam_role.ec2_role.*.name, [""])[0]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

#########################################################
# DFS Namespace EC2 Module
#########################################################

resource "aws_instance" "default" {
  for_each          = var.create ? var.instances : {}
  ami               = data.aws_ami.windows[each.key].id
  instance_type     = each.value.instance_type
  subnet_id         = each.value.subnet_id
  key_name          = var.key_name
  monitoring        = each.value.monitoring
  user_data         = <<EOF
  <powershell>
  Install-WindowsFeature "FS-DFS-Namespace", "FS-DFS-Replication", "RSAT-DFS-Mgmt-Con"
  </powershell>
  EOF
  get_password_data = var.get_password_data
  vpc_security_group_ids = [
    concat(aws_security_group.default.*.id, [""])[0],

  ]
  iam_instance_profile        = concat(aws_iam_instance_profile.ec2_ad_instance_profile.*.name, [""])[0]
  associate_public_ip_address = each.value.associate_public_ip_address
  private_ip                  = lookup(each.value, "private_ip", null)
  ipv6_address_count          = each.value.ipv6_address_count
  ipv6_addresses              = each.value.ipv6_addresses
  ebs_optimized               = each.value.ebs_optimized

  dynamic "root_block_device" {
    for_each = each.value.root_block_device
    content {
      delete_on_termination = lookup(root_block_device.value, "delete_on_termination", null)
      encrypted             = lookup(root_block_device.value, "encrypted", null)
      iops                  = lookup(root_block_device.value, "iops", null)
      kms_key_id            = lookup(root_block_device.value, "kms_key_id", null)
      volume_size           = lookup(root_block_device.value, "volume_size", null)
      volume_type           = lookup(root_block_device.value, "volume_type", null)
    }
  }

  dynamic "ebs_block_device" {
    for_each = each.value.ebs_block_device
    content {
      delete_on_termination = lookup(ebs_block_device.value, "delete_on_termination", null)
      device_name           = ebs_block_device.value.device_name
      encrypted             = lookup(ebs_block_device.value, "encrypted", null)
      iops                  = lookup(ebs_block_device.value, "iops", null)
      kms_key_id            = lookup(ebs_block_device.value, "kms_key_id", null)
      snapshot_id           = lookup(ebs_block_device.value, "snapshot_id", null)
      volume_size           = lookup(ebs_block_device.value, "volume_size", null)
      volume_type           = lookup(ebs_block_device.value, "volume_type", null)
    }
  }

  dynamic "ephemeral_block_device" {
    for_each = each.value.ephemeral_block_device
    content {
      device_name  = ephemeral_block_device.value.device_name
      no_device    = lookup(ephemeral_block_device.value, "no_device", null)
      virtual_name = lookup(ephemeral_block_device.value, "virtual_name", null)
    }
  }

  dynamic "metadata_options" {
    for_each = length(keys(var.metadata_options)) == 0 ? [] : [var.metadata_options]
    content {
      http_endpoint               = lookup(metadata_options.value, "http_endpoint", "enabled")
      http_tokens                 = lookup(metadata_options.value, "http_tokens", "optional")
      http_put_response_hop_limit = lookup(metadata_options.value, "http_put_response_hop_limit", "1")
    }
  }

  dynamic "network_interface" {
    for_each = var.network_interface
    content {
      device_index          = network_interface.value.device_index
      network_interface_id  = lookup(network_interface.value, "network_interface_id", null)
      delete_on_termination = lookup(network_interface.value, "delete_on_termination", false)
    }
  }

  source_dest_check                    = length(var.network_interface) > 0 ? null : var.source_dest_check
  disable_api_termination              = var.disable_api_termination
  instance_initiated_shutdown_behavior = var.instance_initiated_shutdown_behavior
  # placement_group                      = var.placement_group
  tenancy = var.tenancy

  tags = merge(
    local.tags,
    {
      Name = "${local.module_prefix}-${lookup(each.value, "name", each.key)}",
    }
  )
  lifecycle {
    ignore_changes = [
      ami,
    ]
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "dfs_instances" {
  description = "Map of DFS namespace instances"
  value       = { for k, instance in aws_instance.default : k => instance }
}

output "dfs_security_group" {
  description = "List the info for dfs security group"
  value       = aws_security_group.default.*
}

output "dfs_iam_instance_role" {
  description = "List the info for dfs iam instance role"
  value       = aws_iam_role.ec2_role.*
}
