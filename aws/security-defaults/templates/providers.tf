# ----------------------------------------------------------------------------------------------------------------------
# Providers
# ----------------------------------------------------------------------------------------------------------------------
provider "aws" {
  version = "~> 2.26"
  region  = var.aws_region
  skip_region_validation = var.skip_region_validation ? var.skip_region_validation : false
}