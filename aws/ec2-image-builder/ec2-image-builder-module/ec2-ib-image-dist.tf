resource "aws_imagebuilder_distribution_configuration" "ec2_ib_image_dist" {
  name = local.module_prefix

  distribution {
    ami_distribution_configuration {
      ami_tags = {
        CostCenter = "IT"
      }

    region = "us-east-1"
  }
}
