output "kms-cloudwatch-arn" {
  description = "KMS key arn for cloudwatch"
  value       = "${aws_kms_key.cloudwatch.arn}"
}

output "kms-cloudwatch-id" {
  description = "KMS key id for cloudwatch"
  value       = "${aws_kms_key.cloudwatch.key_id}"
}

output "iam-logging" {
  description = "Arn of the Logging role"
  value       = "${aws_iam_role.logging.arn}"
}

output "iam-appsync" {
  description = "Arn of the AppSync role"
  value       = "${aws_iam_role.appsync.arn}"
}

output "s3-public" {
  description = "The name of the public bucket"
  value       = "${aws_s3_bucket.public.bucket}"
}

output "s3-public-arn" {
  description = "The arn of the public bucket"
  value       = "${aws_s3_bucket.public.arn}"
}

output "s3-log" {
  description = "The name of the log bucket"
  value       = "${aws_s3_bucket.log.bucket}"
}

output "s3-log-arn" {
  description = "The arn of the log bucket"
  value       = "${aws_s3_bucket.log.arn}"
}
