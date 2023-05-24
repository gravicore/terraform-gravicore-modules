resource "aws_imagebuilder_image" "ec2_ib_container_latest" {
  distribution_configuration_arn   = aws_imagebuilder_distribution_configuration.ec2_ib_container_dist.arn
  container_recipe_arn             = aws_imagebuilder_container_recipe.ec2_ib_container_recipe.arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.ec2_ib_container_infrastructure.arn

  tags = local.tags

  depends_on = [
    aws_iam_role.aws_iam_instance_profile.image_builder_role,
    aws_imagebuilder_distribution_configuration.aws_imagebuilder_distribution_configuration.ec2_ib_container_dist,
  ]
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------


output "ami_data" {
  value = aws_imagebuilder_image.ec2_ib_container_latest.output_resources
}
