module "aviatrix_controller_iam_roles" {
  source = "github.com/AviatrixSystems/terraform-modules.git/aviatrix-controller-iam-roles"

  master-account-id = "${var.master_account_id}"
}

resource "aviatrix_account" "current" {
  depends_on = ["module.aviatrix_controller_iam_roles"]

  account_name       = "${local.account_name}"
  cloud_type         = "${var.aviatrix_controller_cloud_type}"
  aws_account_number = "${var.account_id}"
  aws_iam            = "true"
  aws_role_app       = "${module.aviatrix_controller_iam_roles.aviatrix-role-app-name}"
  aws_role_ec2       = "${module.aviatrix_controller_iam_roles.aviatrix-role-ec2-name}"
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

