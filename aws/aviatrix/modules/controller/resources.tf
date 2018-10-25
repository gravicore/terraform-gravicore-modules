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

# locals {
#   module_aviatrix_iam_roles_tags = "${merge(local.tags, map(
#     "TerraformModule", "github.com/AviatrixSystems/terraform-modules/aviatrix-controller-iam-roles",
#     "TerraformModuleVersion", "master"))}"
# }

module "aviatrix_iam_roles" {
  source = "github.com/AviatrixSystems/terraform-modules.git//aviatrix-controller-iam-roles"

  # tags   = "${local.module_aviatrix_iam_roles_tags}"

  master-account-id = "${var.master_account_id}"
}

# locals {
#   module_aviatrix_controller_tags = "${merge(local.tags, map(
#     "TerraformModule", "github.com/AviatrixSystems/terraform-modules/aviatrix-controller-build",
#     "TerraformModuleVersion", "master"))}"
# }

module "aviatrix_controller" {
  source = "github.com/AviatrixSystems/terraform-modules.git/aviatrix-controller-build"

  # tags   = "${local.module_aviatrix_controller_tags}"

  vpc     = "${data.terraform_remote_state.vpc.vpc_id}"
  subnet  = "${data.terraform_remote_state.vpc.public_subnets[0]}"
  keypair = "${module.ssh_key_pair.key_name}"
  ec2role = "${module.aviatrix_iam_roles.aviatrix-role-ec2-name}"
}
