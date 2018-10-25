output "bucket" {
  description = "The name of the Terrform remote state S3 bucket"
  value       = "${aws_s3_bucket.remote-state.bucket}"
}

output "table" {
  description = "The name of the Terraform remote state lock table"
  value       = "${aws_dynamodb_table.remote-state-lock.name}"
}

output "terraform_config" {
  description = "Terraform excerpt with state backend configuration. Can be used in multi-environments terraform code."

  value = <<EOF
terraform {
  backend "s3" {
    key            = "{INSERT_KEY}.tfstate"
    bucket         = "${aws_s3_bucket.remote-state.id}"
    dynamodb_table = "${aws_dynamodb_table.remote-state-lock.id}"
    role_arn       = "arn:aws:iam::119494328224:role/grv_deploy_svc"
    region         = "${var.aws_region}"
    encrypt        = true
  }
}
EOF
}
