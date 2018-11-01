locals {
  module_vpc_tags = "${merge(local.tags, map(
    "TerraformModule", "github.com/terraform-aws-modules/terraform-aws-vpc",
    "TerraformModuleVersion", "v1.46.0"))}"
}

module "vpc" {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc?ref=v1.46.0"
  name   = "${local.name_prefix}"
  tags   = "${local.module_vpc_tags}"

  azs                = ["${var.aws_region}a", "${var.aws_region}b"]
  cidr               = "${var.cidr_network}.0.0/16"
  private_subnets    = ["${var.cidr_network}.0.0/19", "${var.cidr_network}.32.0/19"]
  public_subnets     = ["${var.cidr_network}.128.0/20", "${var.cidr_network}.144.0/20"]
  enable_nat_gateway = true
  single_nat_gateway = false
}

# Create a default key/pair for public and private instances
module "ssh_key_pair_public" {
  source    = "git::https://github.com/cloudposse/terraform-aws-key-pair.git?ref=0.2.5"
  namespace = "${var.namespace}"
  stage     = "${var.stage}"
  name      = "${var.environment}-${var.name}-public"
  tags      = "${local.tags}"

  ssh_public_key_path   = "${pathexpand("~/.ssh")}/${var.namespace}"
  generate_ssh_key      = "true"
  private_key_extension = ".pem"
  public_key_extension  = ".pub"
  chmod_command         = "chmod 600 %v"
}

module "ssh_key_pair_private" {
  source    = "git::https://github.com/cloudposse/terraform-aws-key-pair.git?ref=0.2.5"
  namespace = "${var.namespace}"
  stage     = "${var.stage}"
  name      = "${var.environment}-${var.name}-private"
  tags      = "${local.tags}"

  ssh_public_key_path   = "${pathexpand("~/.ssh")}/${var.namespace}"
  generate_ssh_key      = "true"
  private_key_extension = ".pem"
  public_key_extension  = ".pub"
  chmod_command         = "chmod 600 %v"
}

locals {
  module_test_ssh_sg_tags = "${merge(local.tags, map(
    "TerraformModule", "https://registry.terraform.io/modules/terraform-aws-modules/security-group/aws/2.9.0",
    "TerraformModuleVersion", "v1.46.0"))}"
}

module "test_ssh_sg" {
  source      = "terraform-aws-modules/security-group/aws//modules/ssh"
  version     = "2.9.0"
  create      = "${var.create_test_instance}"
  name        = "${local.name_prefix}-test"
  description = "Security group for testing ssh within VPC"
  tags        = "${local.module_test_ssh_sg_tags}"

  vpc_id              = "${module.vpc.vpc_id}"
  ingress_cidr_blocks = "${var.test_ingress_cidr_blocks}"
}

# Test EC2 instance
module "test_ssh_ec2_instance" {
  source           = "git::https://github.com/cloudposse/terraform-aws-ec2-instance.git?ref=0.7.5"
  instance_enabled = "${var.create_test_instance}"
  namespace        = "${var.namespace}"
  stage            = "${var.stage}"
  name             = "${var.name}-test"

  ssh_key_pair    = "${module.ssh_key_pair_private.ssh_key_pair}"
  instance_type   = "${var.test_instance_type}"
  vpc_id          = "${module.vpc.vpc_id}"
  security_groups = ["${module.test_ssh_sg.this_security_group_id}"]
  subnet          = "${module.vpc.module.vpc.private_subnets[0]}"
}
