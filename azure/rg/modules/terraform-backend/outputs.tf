output "sa" {
  value = azurerm_storage_account.tfstate.name
}

# output "terraform_config" {
#   value = <<EOF
# terraform {
#   backend "azurerm" {
#     key            = "{INSERT_KEY}.tfstate"
#     dynamodb_table = "${aws_dynamodb_table.remote-state-lock.id}"
#     role_arn       = "arn:aws:iam::119494328224:role/grv_deploy_svc"
#     region         = "${var.aws_region}"
#     encrypt        = true
#   }
# }
# EOF
# }
