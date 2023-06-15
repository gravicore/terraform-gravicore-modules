terraform {
  required_version = ">= 0.13"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "<= 4.67.0"
    }
  }
}
provider "aws" {
  assume_role {
    role_arn = var.aws_role
  }

  region = var.aws_region
}

#provider "aws" {
#  region     = "${var.aws_region}"
#  access_key = "${var.aws_access_key}"
#  secret_key = "${var.aws_secret_key}"
#}
