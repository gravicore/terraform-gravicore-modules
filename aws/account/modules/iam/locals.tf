data "aws_caller_identity" "this" {}

locals {
  federated_trusted_entities = [
    "arn:aws:iam::${var.trusted_entity_account_id}:saml-provider/grv-saml-provider",
    "${data.aws_caller_identity.this.account_id}"
  ]
  aws_trusted_entities = [
  ]
}

data "template_file" "assume_role_policy" {
  template = <<TEMPLATE
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${var.trusted_entity_account_id}:saml-provider/grv-saml-provider"
      },
      "Action": "sts:AssumeRoleWithSAML",
      "Condition": {
        "StringEquals": {
          "SAML:aud": "https://signin.aws.amazon.com/saml"
        }
      }
    }
  ]
}
TEMPLATE
  vars {}
}
