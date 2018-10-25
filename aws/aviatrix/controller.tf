module "ssh_key_pair" {
  source    = "git::https://github.com/cloudposse/terraform-aws-key-pair.git?ref=0.2.5"
  namespace = "${var.namespace}"
  stage     = "${var.stage}"
  name      = "${var.environment}-${local.name}"
  tags      = "${local.tags}"

  ssh_public_key_path   = "${pathexpand("~/.ssh")}/${var.namespace}"
  generate_ssh_key      = "true"
  private_key_extension = ".pem"
  public_key_extension  = ".pub"
  chmod_command         = "chmod 600 %v"
}

locals {
  module_aviatrix_iam_roles_tags = "${merge(local.tags, map(
    "TerraformModule", "github.com/AviatrixSystems/terraform-modules/aviatrix-controller-iam-roles",
    "TerraformModuleVersion", "master"))}"
}

module "aviatrix_iam_roles" {
  source = "git::https://github.com/AviatrixSystems/terraform-modules.git//aviatrix-controller-iam-roles?ref=master"

  # tags   = "${local.module_aviatrix_iam_roles_tags}"

  master-account-id = "${var.master_account_id}"
}

locals {
  module_aviatrix_controller_tags = "${merge(local.tags, map(
    "TerraformModule", "github.com/AviatrixSystems/terraform-modules/aviatrix-controller-build",
    "TerraformModuleVersion", "master"))}"
}

module "aviatrix_controller" {
  source = "github.com/AviatrixSystems/terraform-modules.git/aviatrix-controller-build"

  # tags   = "${local.module_aviatrix_controller_tags}"

  vpc     = "${data.terraform_remote_state.vpc.vpc_id}"
  subnet  = "${data.terraform_remote_state.vpc.public_subnets[0]}"
  keypair = "${module.ssh_key_pair.key_name}"
  ec2role = "${module.aviatrix_iam_roles.aviatrix-role-ec2-name}"
}

locals {
  module_aviatrix_controller_init_tags = "${merge(local.tags, map(
    "TerraformModule", "github.com/AviatrixSystems/terraform-modules/aviatrix-controller-initialize",
    "TerraformModuleVersion", "master"))}"
}

# specify aviatrix as the provider with these parameters:
# controller_ip - public IP address of the controller
# username - login user name, default is admin
# password - password

provider "aviatrix" {
  controller_ip = "${module.aviatrix_controller.public_ip}"
  username      = "${var.aviatrix_controller_admin_email}"
  password      = "${var.aviatrix_controller_admin_password}"
}

module "aviatrix_controller_init" {
  source = "github.com/AviatrixSystems/terraform-modules.git/aviatrix-controller-initialize"

  admin_email           = "${var.aviatrix_controller_admin_email}"
  admin_password        = "${var.aviatrix_controller_admin_password}"
  private_ip            = "${module.aviatrix_controller.private_ip}"
  public_ip             = "${module.aviatrix_controller.public_ip}"
  aviatrix_account_name = "${var.namespace}-master-prd"
}

# Launch a gateway with these parameters:
# cloud_type - Enter 1 for AWS. Only AWS is currently supported.
# account_name - Aviatrix account name to launch GW with.
# gw_name - Name of gateway.
# vpc_id - AWS VPC ID.
# vpc_reg - AWS VPC region.
# vpc_size - Gateway instance size
# vpc_net - VPC subnet CIDR where you want to launch GW instance


# resource "aviatrix_gateway" "default" {
#   account_name = "${join("-", list(var.namespace, var.environment, var.stage))}"
#   cloud_type   = "${var.aviatrix_controller_cloud_type}"
#   gw_name      = "${local.name_prefix}-gw"
#   vpc_id       = "${data.terraform_remote_state.vpc.vpc_id}"
#   vpc_reg      = "${var.aws_region}"
#   vpc_net      = "${var.vpc_cidr_block}"
#   vpc_size     = "${var.aviatrix_gateway_size}"
# }

