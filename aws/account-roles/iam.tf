# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable allow_gravicore_access {
  description = "Flag to establish SAML connectivity for Gravicore managed services"
  default     = false
}

variable "role_max_session_duration" {
  type        = number
  default     = 43200
  description = "The maximum session duration (in seconds) that you want to set for the specified role. If you do not specify a value for this setting, the default maximum of one hour is applied. This setting can have a value from 1 hour to 12 hours."
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

data "template_file" "assume_role_policy" {
  vars     = {}
  template = <<TEMPLATE
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${var.master_account_id}:root"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
TEMPLATE
}

data "aws_iam_policy_document" "trusted_entities" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [var.master_account_id]
    }
  }
  statement {
    actions = ["sts:AssumeRoleWithSAML"]
    principals {
      type        = "Federated"
      identifiers = local.federated_trusted_entities
    }
  }
}
