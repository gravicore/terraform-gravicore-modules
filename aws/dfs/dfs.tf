# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE / AMI definition
# ----------------------------------------------------------------------------------------------------------------------

variable "vpc_id" {
  type = string
}

variable "vpc_subnet_ids" {
  type = list(string)
}

locals {
  vpc_subnet_ids = flatten(var.vpc_subnet_ids)
}

# DFS Namespace machine
variable "vm_dfs_instance_type" {
  description = "EC2 instance type"
  default     = "t3.medium"
  type        = string
}

variable "vm_dfs_disk_size" {
  description = "EC2 root disk size"
  default     = "60"
  type        = string
}

variable "instance_count" {
  description = "Number of instances to launch"
  type        = number
  default     = 2
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

variable "ebs_optimized" {
  description = "If true, the launched EC2 instance will be EBS-optimized"
  type        = bool
  default     = false
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

variable "monitoring" {
  description = "If true, the launched EC2 instance will have detailed monitoring enabled"
  type        = bool
  default     = false
}

variable "vpc_security_group_ids" {
  description = "A list of security group IDs to associate with"
  type        = list(string)
  default     = null
}

variable "subnet_id" {
  description = "The VPC Subnet ID to launch in"
  type        = string
  default     = ""
}

variable "associate_public_ip_address" {
  description = "If true, the EC2 instance will have associated public IP address"
  type        = bool
  default     = false
}

variable "private_ip" {
  description = "Private IP address to associate with the instance in a VPC"
  type        = string
  default     = null
}

variable "private_ips" {
  description = "A list of private IP address to associate with the instance in a VPC. Should match the number of instances."
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

variable "ipv6_address_count" {
  description = "A number of IPv6 addresses to associate with the primary network interface. Amazon EC2 chooses the IPv6 addresses from the range of your subnet."
  type        = number
  default     = null
}

variable "ipv6_addresses" {
  description = "Specify one or more IPv6 addresses from the range of the subnet to associate with the primary network interface"
  type        = list(string)
  default     = null
}

variable "root_block_device" {
  description = "Customize details about the root block device of the instance. See Block Devices below for details"
  type        = list(map(string))
  default     = []
}

variable "ebs_block_device" {
  description = "Additional EBS block devices to attach to the instance"
  type        = list(map(string))
  default     = []
}

variable "ephemeral_block_device" {
  description = "Customize Ephemeral (also known as Instance Store) volumes on the instance"
  type        = list(map(string))
  default     = []
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
  most_recent = true
  filter {
    name   = "name"
    values = ["Windows_Server-2016-English-Full-Base-*"]
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

variable ingress_cidrs {
  type        = list(string)
  default     = [""]
  description = "description"
}

variable "dfs_tcp_allowed_ports" {
  type = list(object({
    from_port = number
    to_port   = number
  }))
}

variable "dfs_udp_allowed_ports" {
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
  for_each          = { for port in var.dfs_tcp_allowed_ports : port.from_port => port }
  security_group_id = aws_security_group.default[0].id
  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = "tcp"
  cidr_blocks       = var.ingress_cidrs
}

resource "aws_security_group_rule" "allow_ingress_cidr_icmp" {
  count             = var.create ? 1 : 0
  security_group_id = aws_security_group.default[0].id
  type              = "ingress"
  from_port         = "-1"
  to_port           = "-1"
  protocol          = "icmp"
  cidr_blocks       = var.ingress_cidrs
}

resource "aws_security_group_rule" "allow_ingress_cidr_udp" {
  for_each          = { for port in var.dfs_udp_allowed_ports : port.from_port => port }
  security_group_id = aws_security_group.default[0].id
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
  name = join("-", [local.module_prefix, "ec2-ssm-attach"])

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
  name = join("-", [local.module_prefix, "ec2-instance-profile"])
  role = aws_iam_role.ec2_role.name
}

resource "aws_iam_role_policy_attachment" "ec2-ad-role-policy-attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

#########################################################
# DFS Namespace EC2 Module
#########################################################

resource "aws_instance" "default" {
  count             = var.create ? var.instance_count : 0
  ami               = data.aws_ami.windows.id
  instance_type     = var.vm_dfs_instance_type
  subnet_id         = element(var.vpc_subnet_ids, count.index)
  key_name          = var.key_name
  monitoring        = var.monitoring
  user_data         = <<EOF
  <powershell>
  Install-WindowsFeature "FS-DFS-Namespace", "FS-DFS-Replication", "RSAT-DFS-Mgmt-Con"
  </powershell>
  EOF
  get_password_data = var.get_password_data
  vpc_security_group_ids = [
    aws_security_group.default[0].id,

  ]
  iam_instance_profile        = aws_iam_instance_profile.ec2_ad_instance_profile.name
  associate_public_ip_address = var.associate_public_ip_address
  private_ip                  = var.private_ips == null ? null : element(var.private_ips, count.index)
  ipv6_address_count          = var.ipv6_address_count
  ipv6_addresses              = var.ipv6_addresses
  ebs_optimized               = var.ebs_optimized

  dynamic "root_block_device" {
    for_each = var.root_block_device
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
    for_each = var.ebs_block_device
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
    for_each = var.ephemeral_block_device
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
    map(
      "Name", var.instance_count == 1 ? local.module_prefix : join("-", [local.module_prefix, count.index + 1]),
    )
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
  description = "List the info for dfs namespace instances"
  value       = aws_instance.default.*
}
