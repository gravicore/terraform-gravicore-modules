module "aviatrix_controller_iam_roles" {
  source = "github.com/AviatrixSystems/terraform-modules.git//aviatrix-controller-iam-roles?ref=terraform_0.12"

  external-controller-account-id = var.master_account_id
}

output "aviatrix_role_ec2_name" {
  description = "The ARN of the newly created IAM role aviatrix-role-ec2"
  value       = module.aviatrix_controller_iam_roles.aviatrix-role-ec2-name
}

output "aviatrix_role_app_name" {
  description = "The ARN of the newly created IAM role aviatrix-role-app"
  value       = module.aviatrix_controller_iam_roles.aviatrix-role-app-name
}

