terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 3.64.0"
    }
    null = {
      source = "hashicorp/null"
    }    
  }
  required_version = ">= 0.13"
}
