resource "random_string" "password" {
  length  = 16
  special = true
}

locals {
  aviatrix_controller_admin_password = "${var.aviatrix_controller_admin_password == "" ? sha256(bcrypt(random_string.password.result)) : var.aviatrix_controller_admin_password}"

  module_aviatrix_controller_init_tags = "${merge(local.tags, map(
    "TerraformModule", "AviatrixSystems/terraform-modules/aviatrix-controller-initialize",
    "TerraformModuleVersion", "master"))}"
}

module "aviatrix_controller_init" {
  source = "github.com/AviatrixSystems/terraform-modules.git/aviatrix-controller-initialize"

  admin_email           = "${var.aviatrix_controller_admin_email}"
  admin_password        = "${local.aviatrix_controller_admin_password}"
  private_ip            = "${data.terraform_remote_state.aviatrix_controller.private_ip}"
  public_ip             = "${data.terraform_remote_state.aviatrix_controller.public_ip}"
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

