variable "aws_az1" {
  description = "The primary availability zone"
  default     = "us-east-1c"
}

variable "aws_az2" {
  description = "The secondary availability zone"
  default     = "us-east-1e"
}

variable "common_tags" {
  description = "Controls the shared tags"

  default = {
    account_id = ""
    platform   = "grv"
    component  = "sys"
    service    = "vpc"
    stage      = "dev"
    container  = "shr"
    resource   = ""
    grv_tf     = "true"
  }
}
