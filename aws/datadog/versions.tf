terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    datadog = {
      source = "terraform-providers/datadog"
    }
  }
  required_version = ">= 0.13"
}
