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
    "TerraformModule", "registry.terraform.io/modules/terraform-aws-modules/security-group/aws",
    "TerraformModuleVersion", "2.9.0"))}"
}

module "test_ssh_sg" {
  source      = "terraform-aws-modules/security-group/aws//modules/ssh"
  version     = "2.9.0"
  create      = "${var.create_test_instance == "true" ? true : false}"
  name        = "${local.name_prefix}-test"
  description = "Security group for testing ssh within VPC"
  tags        = "${local.module_test_ssh_sg_tags}"

  vpc_id              = "${module.vpc.vpc_id}"
  ingress_cidr_blocks = "${var.test_ingress_cidr_blocks}"
}

# Test EC2 instance
locals {
  module_test_ssh_ec2_instance_tags = "${merge(local.tags, map(
    "TerraformModule", "github.com/cloudposse/terraform-aws-ec2-instance",
    "TerraformModuleVersion", "0.7.5"))}"
}

module "test_ssh_ec2_instance" {
  source           = "git::https://github.com/cloudposse/terraform-aws-ec2-instance.git?ref=0.7.5"
  instance_enabled = "${var.create_test_instance}"
  namespace        = ""
  stage            = ""
  name             = "${local.name_prefix}-test"
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
  zone_id = "${aws_route53_zone.vpc.zone_id}"
  name    = "vpc-test.${local.dns_zone_name}.${data.terraform_remote_state.master_account.parent_domain_name}"
  type    = "A"
  ttl     = "60"
  records = ["${module.test_ssh_ec2_instance.private_ip}"]
}
