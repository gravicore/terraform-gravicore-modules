# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "repos" {
  type        = map(any)
  description = <<EOF
  A map of maps with the key being the repo name, and a sub map containing settings options in the following syntax:
  repos = {
    "rs6-was-ecr" = {
      "image_tag_immutability" = "IMMUTABLE", (string, "IMMUTABLE" or "MUTABLE", defaults to "MUTABLE")
      "scan_on_push" = true,                  (bool,   true or false,            defaults to true)
      "encryption_type" = "AES256",           (string, "AES256" or "KMS",        defaults to "AES256")
      "kms_key" = a KMS key ARN,              (string, any KMS key ARN,          defaults to null)
      }
  }
  EOF
}

variable "image_tag_mutability" {
  type        = string
  description = "The tag mutability setting for the repository. Must be one of: MUTABLE or IMMUTABLE. Defaults to MUTABLE."
  default     = "MUTABLE"
}

variable "scan_on_push" {
  type        = bool
  description = "Indicates whether images are scanned after being pushed to the repository (true) or not scanned (false)"
  default     = true
}

variable "encryption_type" {
  type        = string
  description = "The encryption type to use for the repository. Valid values are AES256 or KMS."
  default     = "AES256"
}

variable "kms_key" {
  type        = string
  description = "The ARN of the KMS key to use when encryption_type is KMS"
  default     = null
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_ecr_repository" "default" {
  for_each             = var.repos
  name                 = each.key
  image_tag_mutability = lookup(each.value, "image_tag_mutability", var.image_tag_mutability)

  image_scanning_configuration {
    scan_on_push = lookup(each.value, "scan_on_push", var.scan_on_push)
  }

  encryption_configuration {
    encryption_type = lookup(each.value, "encryption_type", var.encryption_type)
    kms_key         = lookup(each.value, "kms_key", lookup(each.value, "encryption_type", var.encryption_type) == "KMS" ? var.kms_key : null)
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "ecr" {
  value = aws_ecr_repository.repo
}
