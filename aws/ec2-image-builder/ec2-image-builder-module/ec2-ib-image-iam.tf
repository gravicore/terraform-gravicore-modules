
# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "s3_resource_bucket_name" {
  type        = string
  description = "Name of the S3 bucket to be used for the EC2 Image Builder resources"
}


# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role" "ec2_iam_role" {
  name = "${local.module_prefix}-ec2-ib-iam-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
  inline_policy {
    name = "hardening_instance_inline_policy"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "ssm:DescribeAssociation",
            "ssm:GetDeployablePatchSnapshotForInstance",
            "ssm:GetDocument",
            "ssm:DescribeDocument",
            "ssm:GetManifest",
            "ssm:GetParameter",
            "ssm:GetParameters",
            "ssm:ListAssociations",
            "ssm:ListInstanceAssociations",
            "ssm:PutInventory",
            "ssm:PutComplianceItems",
            "ssm:PutConfigurePackageResult",
            "ssm:UpdateAssociationStatus",
            "ssm:UpdateInstanceAssociationStatus",
            "ssm:UpdateInstanceInformation",
            "ssmmessages:CreateControlChannel",
            "ssmmessages:CreateDataChannel",
            "ssmmessages:OpenControlChannel",
            "ssmmessages:OpenDataChannel",
            "ec2messages:AcknowledgeMessage",
            "ec2messages:DeleteMessage",
            "ec2messages:FailMessage",
            "ec2messages:GetEndpoint",
            "ec2messages:GetMessages",
            "ec2messages:SendReply",
            "ec2:CreateTags",
            "imagebuilder:GetComponent",
            "imagebuilder:GetContainerRecipe",
            "ecr:GetAuthorizationToken",
            "ecr:BatchGetImage",
            "ecr:InitiateLayerUpload",
            "ecr:UploadLayerPart",
            "ecr:CompleteLayerUpload",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:PutImage"
          ],
          "Resource" : [
            "*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "s3:List*",
            "s3:GetObject",
            "S3:GetBucketPolicy",
            "S3:PutBucketPolicy"
          ],
          "Resource" : [
            "*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "s3:PutObject"
          ],
          "Resource" : [
            "arn:aws:s3:::${var.s3_resource_bucket_name}/image-builder/*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "logs:CreateLogStream",
            "logs:CreateLogGroup",
            "logs:PutLogEvents"
          ],
          "Resource" : [
            "arn:aws:logs:*:*:log-group:/aws/imagebuilder/*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "kms:Decrypt"
          ],
          "Resource" : [
            "*"
          ],
          "Condition" : {
            "ForAnyValue:StringEquals" : {
              "kms:EncryptionContextKeys" : "aws:imagebuilder:arn"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "s3:GetObject"
          ],
          "Resource" : [
            "arn:aws:s3:::ec2imagebuilder*"
          ]
        },
        {
          "Sid" : "Ec2ImageBuilderCrossAccountDistributionAccessTags",
          "Effect" : "Allow",
          "Action" : [
            "ec2:CreateTags"
          ],
          "Resource" : [
            "arn:aws:ec2:*::image/*"
          ]
        },
        {
          "Sid" : "Ec2ImageBuilderCrossAccountDistributionAccess",
          "Effect" : "Allow",
          "Action" : [
            "ec2:DescribeImages",
            "ec2:CopyImage",
            "ec2:ModifyImageAttribute"
          ],
          "Resource" : [
            "*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : "inspector2:*",
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : "iam:CreateServiceLinkedRole",
          "Resource" : "*",
          "Condition" : {
            "StringEquals" : {
              "iam:AWSServiceName" : "inspector2.amazonaws.com"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "organizations:EnableAWSServiceAccess",
            "organizations:RegisterDelegatedAdministrator",
            "organizations:ListDelegatedAdministrators",
            "organizations:ListAWSServiceAccessForOrganization",
            "organizations:DescribeOrganizationalUnit",
            "organizations:DescribeAccount",
            "organizations:DescribeOrganization"
          ],
          "Resource" : "*"
        }
      ]
    })
  }
}

# Create the EC2 Instance Profile to use for the image
resource "aws_iam_instance_profile" "image_builder_role" {
  name = "${local.module_prefix}-ec2-ib-iam-instance-profile"
  role = aws_iam_role.ec2_iam_role.name
}



# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "ec2_image_builder_role_arn" {
  value = aws_iam_instance_profile.image_builder_role.arn
}
