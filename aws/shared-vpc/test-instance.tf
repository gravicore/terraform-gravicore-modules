# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "create_test_instance" {
  default = "false"
}

variable "test_instance_type" {
  default = "t2.nano"
}

variable "test_ingress_cidr_block" {
  default = "10.0.0.0/8"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

# Create a default key/pair for public and private instances

locals {
  module_test_ssh_key_pair_public_tags = "${merge(local.tags, map(
    "TerraformModule", "cloudposse/terraform-aws-key-pair",
    "TerraformModuleVersion", "0.2.5"))}"
}

module "ssh_key_pair_public" {
  source    = "git::https://github.com/cloudposse/terraform-aws-key-pair.git?ref=0.2.5"
  namespace = "${var.namespace}"
  stage     = "${var.stage}"
  name      = "${var.environment}-${var.name}-public"
  tags      = "${local.module_test_ssh_key_pair_public_tags}"

  ssh_public_key_path   = "${pathexpand("~/.ssh")}/${var.namespace}"
  generate_ssh_key      = "true"
  private_key_extension = ".pem"
  public_key_extension  = ".pub"
  chmod_command         = "chmod 600 %v"
}

locals {
  module_test_ssh_key_pair_private_tags = "${merge(local.tags, map(
    "TerraformModule", "gravicore/terraform-gravicore-modules/aws/shared-vpc/key-pair",
    "TerraformModuleVersion", "issues/4"))}"
}

module "ssh_key_pair_private" {
  source    = "./key-pair"
  namespace = "${var.namespace}"
  stage     = "${var.stage}"
  name      = "${var.environment}-${var.name}-private"
  tags      = "${local.module_test_ssh_key_pair_private_tags}"

  ssh_public_key_path   = "${pathexpand("~/.ssh")}/${var.namespace}"
  generate_ssh_key      = "true"
  private_key_extension = ".pem"
  public_key_extension  = ".pub"
  chmod_command         = "chmod 600 %v"
}

locals {
  module_test_ssh_ec2_instance_secret_tags = "${merge(local.tags, map(
    "TerraformModule", "cloudposse/terraform-aws-ssm-parameter-store",
    "TerraformModuleVersion", "0.2.5"))}"
}

module "test_ssh_ec2_instance_secret" {
  source = "git::https://github.com/cloudposse/terraform-aws-ssm-parameter-store?ref=0.1.5"
  tags   = "${local.module_test_ssh_ec2_instance_secret_tags}"

  kms_arn = "alias/parameter_store_key"

  parameter_write = [
    {
      name        = "/${local.stage_prefix}/${var.name}-test-pem"
      value       = "${module.ssh_key_pair_private.private_key}"
      type        = "SecureString"
      overwrite   = "true"
      description = "${join(" ", list(var.desc_prefix, "VPC Test SSH Instance Private Key"))}"
    },
    {
      name        = "/${local.stage_prefix}/${var.name}-test-pub"
      value       = "${module.ssh_key_pair_private.public_key}"
      type        = "SecureString"
      overwrite   = "true"
      description = "${join(" ", list(var.desc_prefix, "VPC Test SSH Instance Public Key"))}"
    },
  ]
}

locals {
  module_test_ssh_sg_tags = "${merge(local.tags, map(
    "TerraformModule", "terraform-aws-modules/security-group/aws",
    "TerraformModuleVersion", "2.9.0"))}"
}

module "test_ssh_sg" {
  source      = "terraform-aws-modules/security-group/aws//modules/ssh"
  version     = "2.9.0"
  create      = "${var.create_test_instance == "true" ? true : false}"
  name        = "${local.module_prefix}-test"
  description = "${join(" ", list(var.desc_prefix, "Test SSH Instance"))}"
  tags        = "${local.module_test_ssh_sg_tags}"

  vpc_id              = "${module.vpc.vpc_id}"
  ingress_cidr_blocks = ["${var.test_ingress_cidr_block}"]

  ingress_with_cidr_blocks = [
    {
      from_port   = -1
      to_port     = -1
      protocol    = "icmp"
      description = "All ICMP - IPv4"
      cidr_blocks = "${var.test_ingress_cidr_block}"
    },
  ]
}

# Test EC2 instance
locals {
  module_test_ssh_ec2_instance_tags = "${merge(local.tags, map(
    "TerraformModule", "cloudposse/terraform-aws-ec2-instance",
    "TerraformModuleVersion", "0.7.5"))}"
}

module "test_ssh_ec2_instance" {
  source           = "git::https://github.com/cloudposse/terraform-aws-ec2-instance.git?ref=0.7.5"
  instance_enabled = "${var.create_test_instance}"
  namespace        = ""
  stage            = ""
  name             = "${local.module_prefix}-test"
  tags             = "${local.module_test_ssh_ec2_instance_tags}"

  ssh_key_pair                = "${module.ssh_key_pair_private.key_name}"
  instance_type               = "${var.test_instance_type}"
  vpc_id                      = "${module.vpc.vpc_id}"
  security_groups             = ["${module.test_ssh_sg.this_security_group_id}"]
  subnet                      = "${module.vpc.private_subnets[0]}"
  assign_eip_address          = "false"
  associate_public_ip_address = "false"
}

resource "aws_route53_record" "test_ssh_ec2_instance" {
  provider = "aws.master"

  zone_id = "${aws_route53_zone.vpc.zone_id}"
  name    = "test.${local.dns_zone_name}"
  type    = "A"
  ttl     = "60"
  records = ["${module.test_ssh_ec2_instance.private_ip}"]
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

