module "ssh_key_pair" {
  source    = "git::https://github.com/cloudposse/terraform-aws-key-pair.git?ref=0.2.5"
  namespace = "${var.namespace}"
  stage     = "${var.stage}"
  name      = "${var.environment}-${var.name}"
  tags      = "${local.tags}"

  ssh_public_key_path   = "${pathexpand("~/.ssh")}/${var.namespace}"
  generate_ssh_key      = "true"
  private_key_extension = ".pem"
  public_key_extension  = ".pub"
  chmod_command         = "chmod 600 %v"
}

locals {
  module_vgw_tags = "${merge(local.tags, map(
    "Name", "${join("-", list(var.namespace, var.environment, var.stage, "transit-vgw"))}"
  ))}"
}

resource "aws_vpn_gateway" "vgw" {
  vpc_id = "${aws_vpc.main.id}"

  tags = "${local.module_vgw_tags}"
}

module "aviatrix_controller" {
  source = "git::https://github.com/mike-r-mclaughlin/terraform-modules.git//aviatrix-controller-build?ref=0cd96b8"

  vpc     = "${data.terraform_remote_state.vpc.vpc_id}"
  subnet  = "${data.terraform_remote_state.vpc.public_subnets[0]}"
  keypair = "${module.ssh_key_pair.key_name}"
  ec2role = "aviatrix-role-ec2"
}
