# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "repository_name_suffix" {
  type        = string
  description = "The suffix of your GIT repository's name"
  default     = ""
}

variable "repository_description" {
  type        = string
  description = "The description of your GIT repository"
  default     = "Master infrastructure"
}

variable "default_branch" {
  type        = string
  description = "The name of the default repository branch"
  default     = "master"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_codecommit_repository" "repo" {
  repository_name = replace(
    "${local.environment_prefix}-${var.stage}-${var.repository_name_suffix}",
    "-prd",
    "",
  )
  description    = "${var.desc_prefix}${var.repository_description}"
  default_branch = var.default_branch
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "repository_id" {
  value = aws_codecommit_repository.repo.id
}

output "repository_arn" {
  value = aws_codecommit_repository.repo.arn
}

output "clone_url_https" {
  value = aws_codecommit_repository.repo.clone_url_http
}

output "clone_url_ssh" {
  value = aws_codecommit_repository.repo.clone_url_ssh
}

