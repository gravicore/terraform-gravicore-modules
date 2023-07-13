terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      aws      = ">= 2.26"
    }
    random = {
      source = "hashicorp/random"
    }
  }
  required_version = ">= 0.13"
}
