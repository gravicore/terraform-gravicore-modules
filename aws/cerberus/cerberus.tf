# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "number_of_instances" {
  description = "The number of EC2 instances to create"
  default     = 1
}

variable "ingress_sg_cidr" {
  description = "List of the ingress cidr's to create the security group."
  default     = ["10.0.0.0/8"]
}

variable "cerberus_instance_type" {
  description = "Instance type for Cerberus EC2 instance"
  default     = "t3.medium"
}

variable "cerberus_instance_ami" {
  description = "ami for Cerberus EC2 instance"
  default     = "ami-0a7d688fe3e239b69"
}

variable "ebs_volume_size" {
  description = "Size in gb of ebs volume to be created"
  default     = "30"
}

variable "termination_protection" {
  description = "Enables termination protection for ec2 instace. Must be set to false and applied before ec2 instance can be terminated"
  default     = true
}

variable "alb_ssl_certificate" {}

variable "schedule" {
  description = "Instance scheduler schedule to set RC2 instance to"
  default     = ""
}

variable "ssh_key_name" {
  description = "Name of ssh key located in parameter store"
  default     = "vpc-private-pub"
}

variable "terraform_remote_state_acct_key" {
  description = "Key for the location of the remote state of the acct module"
  default     = ""
}

variable "terraform_remote_state_vpc_key" {
  description = "Key for the location of the remote state of the vpc module"
  default     = ""
}

variable "directory_ou" {
  description = "(Optional) The Organizational Unit (OU) and Directory Components (DC) for the directory; for example, OU=test,DC=example,DC=com"
  default     = ""
}

variable "add_instance_to_ad" {
  description = "Add ec2 instance to ad"
  default     = "true"
}

variable "enable_https" {
  description = "Adds infrastructure nessesary for https"
  default     = "true"
}

variable "https_health_check_interval" {
  description = "Average interval for https health check. Allowed Values:5-300"
  default     = "300"
}

variable "https_health_check_threshold" {
  description = "Healthy/unhelthy threshold for https health check. Allowed Values:2-10"
  default     = "2"
}

variable "https_health_check_timeout" {
  description = "Timeout for https health check. Allowed Values:2-120"
  default     = "5"
}

variable "enable_sftp" {
  description = "Adds infrastructure nessesary for sftp"
  default     = "true"
}

variable "sftp_health_check_interval" {
  description = "Average interval for sftp health check. Allowed Values:10, 30"
  default     = "30"
}

variable "sftp_health_check_threshold" {
  description = "Healthy/unhelthy threshold for sftp health check. Allowed Values:2-10"
  default     = "2"
}

variable "alb_target_group_port" {
  description = "EC2 target group port from ALB."
  default     = "80"
}

variable "alb_target_group_protocol" {
  description = "EC2 target group protocol from ALB."
  default     = "HTTP"
}

variable "parent_domain_name" {}

locals {
  module_kms_key_tags = "${merge(local.tags, map(
    "TerraformModule", "cloudposse/terraform-aws-kms-key",
    "TerraformModuleVersion", "0.1.2"))}"

  remote_state_acct_key = "${coalesce(var.terraform_remote_state_acct_key, "master/${var.stage}/acct")}"
  remote_state_vpc_key  = "${coalesce(var.terraform_remote_state_vpc_key, "master/${var.stage}/shared-vpc")}"
}

data "terraform_remote_state" "acct" {
  backend = "s3"

  config {
    region         = "${var.aws_region}"
    bucket         = "${var.namespace}-master-prd-tf-state-${var.master_account_id}"
    encrypt        = true
    key            = "${local.remote_state_acct_key}/terraform.tfstate"
    dynamodb_table = "${var.namespace}-master-prd-tf-state-lock"
    role_arn       = "arn:aws:iam::${var.master_account_id}:role/${var.master_account_assume_role_name}"
  }
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config {
    region         = "${var.aws_region}"
    bucket         = "${var.namespace}-master-prd-tf-state-${var.master_account_id}"
    encrypt        = true
    key            = "${local.remote_state_vpc_key}/terraform.tfstate"
    dynamodb_table = "${var.namespace}-master-prd-tf-state-lock"
    role_arn       = "arn:aws:iam::${var.master_account_id}:role/${var.master_account_assume_role_name}"
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

module "cerberus_kms_key" {
  source                  = "git::https://github.com/cloudposse/terraform-aws-kms-key.git?ref=0.1.2"
  namespace               = ""
  stage                   = ""
  name                    = "${local.stage_prefix}-cerberus"
  description             = "${join(" ", list(var.desc_prefix, "KMS key for Cerberus"))}"
  deletion_window_in_days = 10
  enable_key_rotation     = "true"
  alias                   = "alias/${replace(local.stage_prefix, "-", "/")}/cerberus"
  tags                    = "${local.module_kms_key_tags}"
}

resource "aws_security_group" "cerberus_ec2" {
  count       = "${var.create ? 1 : 0 }"
  name        = "${local.module_prefix}-ec2"
  description = "${var.desc_prefix} Allow traffic to Cerberus EC2 application instances"
  vpc_id      = "${data.terraform_remote_state.vpc.vpc_id}"

  ingress {
    from_port       = "${var.alb_target_group_port}"
    to_port         = "${var.alb_target_group_port}"
    protocol        = "6"
    security_groups = ["${aws_security_group.cerberus_alb.id}"]
    description     = "${var.desc_prefix} Target group port from ALB"
  }

  ingress {
    from_port   = "3389"
    to_port     = "3389"
    protocol    = "6"
    cidr_blocks = ["${var.ingress_sg_cidr}"]
    description = "${var.desc_prefix} RDP from internal"
  }

  ingress {
    from_port   = "8443"
    to_port     = "8443"
    protocol    = "6"
    cidr_blocks = ["${var.ingress_sg_cidr}"]
    description = "${var.desc_prefix} Cerberus Web Administration from internal"
  }

  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "6"
    cidr_blocks = ["0.0.0.0/0"]
    description = "${var.desc_prefix} SSH/SFTP"
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "ICMP"
    cidr_blocks = ["${var.ingress_sg_cidr}"]
    description = "${var.desc_prefix} ICMP from internal"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "${var.desc_prefix} Allow All"
  }

  tags = "${merge(local.tags, map("Name", "${local.module_prefix}-ec2"))}"
}

data "aws_iam_policy_document" "cerberus_ec2" {
  count = "${var.create ? 1 : 0 }"

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cerberus_ec2" {
  count              = "${var.create ? 1 : 0 }"
  name               = "${local.module_prefix}-ec2"
  description        = "${var.desc_prefix} Allows EC2 instances to call AWS services on your behalf."
  assume_role_policy = "${data.aws_iam_policy_document.cerberus_ec2.json}"
}

resource "aws_iam_role_policy_attachment" "cerberus_ssm_attach" {
  count      = "${var.create ? 1 : 0 }"
  role       = "${aws_iam_role.cerberus_ec2.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_instance_profile" "cerberus_profile" {
  count = "${var.create ? 1 : 0 }"
  name  = "${local.module_prefix}-ec2"
  role  = "${aws_iam_role.cerberus_ec2.name}"
}

resource "aws_ebs_volume" "cerberus_ebs" {
  count             = "${var.create ? var.number_of_instances : 0}"
  availability_zone = "${aws_instance.cerberus_ec2.*.availability_zone[count.index]}"
  size              = "${var.ebs_volume_size}"
  type              = "gp2"
  encrypted         = true
  kms_key_id        = "${data.terraform_remote_state.acct.ebs_key_arn}"
  tags              = "${merge(local.tags, map("Name", format("${local.module_prefix}-%d", count.index + 1)))}"
}

resource "aws_volume_attachment" "cerberus" {
  count       = "${var.create ? var.number_of_instances : 0}"
  device_name = "/dev/sdb"
  volume_id   = "${aws_ebs_volume.cerberus_ebs.*.id[count.index]}"
  instance_id = "${aws_instance.cerberus_ec2.*.id[count.index]}"
}

resource "aws_instance" "cerberus_ec2" {
  count         = "${var.create ? var.number_of_instances : 0}"
  instance_type = "${var.cerberus_instance_type}"
  ami           = "${var.cerberus_instance_ami}"

  iam_instance_profile = "${aws_iam_instance_profile.cerberus_profile.name}"

  key_name = "${var.namespace}-${var.stage}-${var.environment}-vpc-private"

  vpc_security_group_ids = ["${aws_security_group.cerberus_ec2.id}"]

  subnet_id = "${data.terraform_remote_state.vpc.vpc_private_subnets[count.index + 1 == length(data.terraform_remote_state.vpc.vpc_private_subnets) ? 0 : count.index + 1]}"

  # Enables termination protection. Must be set to false and applied before inctance can be removed.
  disable_api_termination = "${var.termination_protection}"
  monitoring              = true
  ebs_optimized           = true

  tags = "${merge(local.tags, map("Name", format("${local.module_prefix}-%d", count.index + 1), "Schedule", format("%s", var.schedule)))}"

  lifecycle {
    ignore_changes = ["tags.%", "tags.Schedule", "tags.ScheduleStatus", "tags.ScheduleTimestamp"]
  }
}

resource "aws_ssm_association" "domain_join" {
  count = "${var.create && var.add_instance_to_ad ? var.number_of_instances : 0}"
  name  = "AWS-JoinDirectoryServiceDomain"

  instance_id = "${aws_instance.cerberus_ec2.*.id[count.index]}"

  parameters {
    directoryId   = "${data.terraform_remote_state.vpc.ds_directory_id}"
    directoryName = "${data.terraform_remote_state.vpc.ds_domain_name}"
    directoryOU   = "${var.directory_ou}"
  }
}

resource "aws_route53_record" "cerberus_ec2" {
  count    = "${var.create ? var.number_of_instances : 0}"
  provider = "aws.master"

  zone_id = "${data.terraform_remote_state.vpc.vpc_dns_zone_id}"
  name    = "${var.name}-${format("%d", count.index + 1 )}"
  type    = "CNAME"
  ttl     = "30"
  records = ["${aws_instance.cerberus_ec2.*.private_dns[count.index]}"]
}

# ALB & resources

resource "aws_security_group" "cerberus_alb" {
  count       = "${var.create ? 1 : 0 }"
  name        = "${local.module_prefix}-alb"
  description = "${var.desc_prefix} Controls traffic to ALB"
  vpc_id      = "${data.terraform_remote_state.vpc.vpc_id}"

  ingress {
    from_port   = "80"
    to_port     = "80"
    protocol    = "6"
    cidr_blocks = ["0.0.0.0/0"]
    description = "${var.desc_prefix} HTTP"
  }

  ingress {
    from_port   = "443"
    to_port     = "443"
    protocol    = "6"
    cidr_blocks = ["0.0.0.0/0"]
    description = "${var.desc_prefix} HTTPS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "${var.desc_prefix} Allow All"
  }

  tags = "${merge(local.tags, map("Name", "${local.module_prefix}-alb"))}"
}

resource "aws_lb" "cerberus_alb" {
  count = "${var.create && var.enable_https ? 1 : 0 }"

  name               = "${local.module_prefix}-alb"
  internal           = "false"
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.cerberus_alb.id}"]
  subnets            = ["${data.terraform_remote_state.vpc.vpc_public_subnets}"]
  idle_timeout       = "60"

  tags = "${local.tags}"
}

resource "aws_lb_target_group" "cerberus_alb_target_group" {
  count = "${var.create && var.enable_https ? 1 : 0 }"

  name                 = "${local.module_prefix}-${lower(var.alb_target_group_protocol)}"
  port                 = "${var.alb_target_group_port}"
  protocol             = "${var.alb_target_group_protocol}"
  vpc_id               = "${data.terraform_remote_state.vpc.vpc_id}"
  target_type          = "instance"
  deregistration_delay = "300"

  health_check {
    path                = "/login"
    protocol            = "${var.alb_target_group_protocol}"
    timeout             = "${var.https_health_check_timeout}"
    healthy_threshold   = "${var.https_health_check_threshold}"
    unhealthy_threshold = "${var.https_health_check_threshold}"
    interval            = "${var.https_health_check_interval}"
    matcher             = "200"
  }

  tags = "${local.tags}"
}

resource "aws_lb_listener" "cerberus_https" {
  count             = "${var.create && var.enable_https ? 1 : 0 }"
  load_balancer_arn = "${aws_lb.cerberus_alb.arn}"
  port              = "443"
  protocol          = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-2016-08"
  certificate_arn = "${var.alb_ssl_certificate}"

  default_action {
    target_group_arn = "${aws_lb_target_group.cerberus_alb_target_group.arn}"
    type             = "forward"
  }
}

resource "aws_lb_listener" "cerberus_http" {
  count             = "${var.create && var.enable_https ? 1 : 0 }"
  load_balancer_arn = "${aws_lb.cerberus_alb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }

    type = "redirect"
  }
}

resource "aws_lb_target_group_attachment" "cerberus" {
  count            = "${var.create && var.enable_https ? var.number_of_instances : 0}"
  target_group_arn = "${aws_lb_target_group.cerberus_alb_target_group.arn}"
  target_id        = "${aws_instance.cerberus_ec2.*.id[count.index]}"
}

data "aws_route53_zone" "public" {
  provider = "aws.master"
  name     = "${var.parent_domain_name}"
}

resource "aws_route53_record" "cerberus_alb" {
  count    = "${var.create && var.enable_https ? 1 : 0 }"
  provider = "aws.master"

  zone_id = "${data.aws_route53_zone.public.zone_id}"
  name    = "transfer"
  type    = "CNAME"
  ttl     = "30"
  records = ["${aws_lb.cerberus_alb.dns_name}"]
}

# NLB & resources

resource "aws_lb" "cerberus_nlb" {
  count = "${var.create && var.enable_sftp ? 1 : 0 }"

  name                             = "${local.module_prefix}-nlb"
  internal                         = "false"
  load_balancer_type               = "network"
  enable_cross_zone_load_balancing = "true"
  subnets                          = ["${data.terraform_remote_state.vpc.vpc_public_subnets}"]
  idle_timeout                     = "60"

  tags = "${local.tags}"
}

resource "aws_lb_target_group" "cerberus_nlb_sftp_target_group" {
  count = "${var.create && var.enable_sftp ? 1 : 0 }"

  name                 = "${local.module_prefix}-sftp"
  port                 = "22"
  protocol             = "TCP"
  vpc_id               = "${data.terraform_remote_state.vpc.vpc_id}"
  target_type          = "instance"
  deregistration_delay = "300"

  health_check {
    port                = "traffic-port"
    protocol            = "TCP"
    healthy_threshold   = "${var.sftp_health_check_threshold}"
    unhealthy_threshold = "${var.sftp_health_check_threshold}"
    interval            = "${var.sftp_health_check_interval}"
  }

  tags = "${local.tags}"
}

resource "aws_lb_listener" "cerberus_sftp" {
  count             = "${var.create && var.enable_sftp ? 1 : 0 }"
  load_balancer_arn = "${aws_lb.cerberus_nlb.arn}"
  port              = "22"
  protocol          = "TCP"

  default_action {
    target_group_arn = "${aws_lb_target_group.cerberus_nlb_sftp_target_group.arn}"
    type             = "forward"
  }
}

resource "aws_lb_target_group_attachment" "cerberus_sftp" {
  count            = "${var.create && var.enable_sftp ? var.number_of_instances : 0}"
  target_group_arn = "${aws_lb_target_group.cerberus_nlb_sftp_target_group.arn}"
  target_id        = "${aws_instance.cerberus_ec2.*.id[count.index]}"
}

resource "aws_route53_record" "cerberus_nlb" {
  count    = "${var.create && var.enable_sftp ? 1 : 0 }"
  provider = "aws.master"

  zone_id = "${data.aws_route53_zone.public.zone_id}"
  name    = "sftp"
  type    = "CNAME"
  ttl     = "30"
  records = ["${aws_lb.cerberus_nlb.dns_name}"]
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "ec2_security_group_name" {
  value = "${join("", aws_security_group.cerberus_ec2.*.name)}"
}

output "ec2_security_group_id" {
  value = "${join("", aws_security_group.cerberus_ec2.*.id)}"
}

output "ec2_iam_role_name" {
  value = "${join("", aws_iam_role.cerberus_ec2.*.name)}"
}

output "ec2_ebs_volume_id" {
  value = "${aws_ebs_volume.cerberus_ebs.*.id}"
}

output "ec2_instance_id" {
  value = "${aws_instance.cerberus_ec2.*.id}"
}

output "ec2_instance_private_ip" {
  value = "${aws_instance.cerberus_ec2.*.private_ip}"
}

output "ec2_instance_private_dns" {
  value = "${aws_instance.cerberus_ec2.*.private_dns}"
}

output "ec2_instance_key_pair_name" {
  value = "${aws_instance.cerberus_ec2.*.key_name}"
}

output "ec2_instance_route53_dns" {
  value = "${aws_route53_record.cerberus_ec2.*.name}"
}

output "alb_security_group_name" {
  value = "${join("", aws_security_group.cerberus_alb.*.name)}"
}

output "alb_security_group_id" {
  value = "${join("", aws_security_group.cerberus_alb.*.id)}"
}

output "alb_id" {
  value = "${join("", aws_lb.cerberus_alb.*.id)}"
}

output "alb_dns_name" {
  value = "${join("", aws_lb.cerberus_alb.*.dns_name)}"
}

output "alb_instance_route53_dns" {
  value = "${join("", aws_route53_record.cerberus_alb.*.name)}"
}

output "alb_instance_route53_dns_fqdn" {
  value = "${join("", aws_route53_record.cerberus_alb.*.fqdn)}"
}

output "nlb_id" {
  value = "${join("", aws_lb.cerberus_nlb.*.id)}"
}

output "nlb_dns_name" {
  value = "${join("", aws_lb.cerberus_nlb.*.dns_name)}"
}

output "nlb_instance_route53_dns" {
  value = "${join("", aws_route53_record.cerberus_nlb.*.name)}"
}

output "nlb_instance_route53_dns_fqdn" {
  value = "${join("", aws_route53_record.cerberus_nlb.*.fqdn)}"
}

output "cerberus_key_arn" {
  value       = "${module.cerberus_kms_key.key_arn}"
  description = "Key ARN for Cerberus"
}
