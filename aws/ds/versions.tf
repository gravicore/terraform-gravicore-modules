terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.74.1"
    }
    random = {
      source = "hashicorp/random"
    }
  }
  required_version = ">= 0.13"
}
