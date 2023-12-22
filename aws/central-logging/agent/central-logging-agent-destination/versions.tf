terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.26"
    }
  }
  required_version = ">= 0.13"
}
