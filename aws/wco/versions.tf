terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      aws      = ">= 2.26"
    }
  }
  required_version = ">= 0.13"
}
