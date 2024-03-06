# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "app_runner_ecr_arn" {
  type        = string
  description = "ARN of the ECR Repository containing the image to be deployed in App Runner"
}


# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------


resource "aws_iam_role" "app_runner_ecr_auth_role" {
  name = "java-poc-ecr-auth-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "build.apprunner.amazonaws.com"
        }
      }
    ]
  })
}


resource "aws_iam_role_policy" "ecr_auth_policy" {

  name = "java-poc-ecr-auth-policy"
  role = aws_iam_role.app_runner_ecr_auth_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetAuthorizationToken"
        ]
        Effect   = "Allow"
        Resource = var.app_runner_ecr_arn
      }
    ]
  })
}


# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------


output "ecr_auth_access_role_arn" {
  value = aws_iam_role.app_runner_ecr_auth_role.arn
}
