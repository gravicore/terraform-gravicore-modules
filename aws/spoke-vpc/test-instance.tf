# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "create_test_instance" {
  default = false
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

locals {
  module_test_ssh_sg_tags = merge(
    local.tags,
    {
      "TerraformModule"        = "terraform-aws-modules/security-group/aws"
      "TerraformModuleVersion" = "2.9.0"
    },
  )
}

module "test_ssh_sg" {
  source      = "terraform-aws-modules/security-group/aws//modules/ssh"
  version     = "3.1.0"
  create      = var.create_test_instance ? true : false
  name        = "${local.module_prefix}-test"
  description = join(" ", [var.desc_prefix, "Test SSH Instance"])
  tags        = local.module_test_ssh_sg_tags

  vpc_id              = module.vpc.vpc_id
  ingress_cidr_blocks = [var.test_ingress_cidr_block]

  ingress_with_cidr_blocks = [
    {
      from_port   = -1
      to_port     = -1
      protocol    = "icmp"
      description = "All ICMP - IPv4"
      cidr_blocks = var.test_ingress_cidr_block
    },
  ]
}

# Test EC2 instance
locals {
  module_test_ssh_ec2_instance_tags = merge(
    local.tags,
    {
      "TerraformModule"        = "cloudposse/terraform-aws-ec2-instance"
      "TerraformModuleVersion" = "0.7.5"
    },
  )
}

module "test_ssh_ec2_instance" {
  # source                        = "git::https://github.com/cloudposse/terraform-aws-ec2-instance.git?ref=0.8.0"
  source = "git::https://github.com/PrimeDiscoveries/terraform-aws-ec2-instance.git?ref=master"

  instance_enabled              = var.create_test_instance
  create_default_security_group = var.create_test_instance
  namespace                     = ""
  stage                         = ""
  name                          = "${local.module_prefix}-test"
  tags                          = local.module_test_ssh_ec2_instance_tags

  ssh_key_pair                = module.ssh_key_pair_private.key_name
  instance_type               = var.test_instance_type
  vpc_id                      = module.vpc.vpc_id
  security_groups             = [module.test_ssh_sg.this_security_group_id]
  subnet                      = module.vpc.private_subnets[0]
  assign_eip_address          = false
  associate_public_ip_address = false
}

resource "aws_route53_record" "test_ssh_ec2_instance" {
  count    = var.create_test_instance ? 1 : 0
  provider = aws.master

  zone_id = aws_route53_zone.vpc[0].zone_id
  name    = "test.${local.dns_zone_name}"
  type    = "A"
  ttl     = "60"

  records = [module.test_ssh_ec2_instance.private_ip]
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------
