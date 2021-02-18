# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "attributes" {
  type        = list(string)
  default     = []
  description = "Additional attributes (e.g. `1`)"
}

variable "acm_certificate_arn" {
  type        = string
  description = "Existing ACM Certificate ARN"
  default     = ""
}

variable "minimum_protocol_version" {
  type        = string
  description = "Cloudfront TLS minimum protocol version"
  default     = "TLSv1.1_2016"
}

variable "aliases" {
  type        = list(string)
  description = "List of FQDN's - Used to set the Alternate Domain Names (CNAMEs) setting on Cloudfront"
  default     = []
}

variable "external_aliases" {
  type        = list(string)
  description = "List of FQDN's not associated with Route 53- Used to set the Alternate Domain Names (CNAMEs) setting on Cloudfront"
  default     = []
}

variable "use_regional_s3_endpoint" {
  type        = bool
  description = "When set to 'true' the s3 origin_bucket will use the regional endpoint address instead of the global endpoint address"
  default     = false
}

variable "origin_bucket" {
  type        = string
  default     = ""
  description = "Origin S3 bucket name"
}

variable "origin_path" {
  # http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-web-values-specify.html#DownloadDistValuesOriginPath
  type        = string
  description = "An optional element that causes CloudFront to request your content from a directory in your Amazon S3 bucket or your custom origin. It must begin with a /. Do not add a / at the end of the path."
  default     = ""
}

variable "origin_force_destroy" {
  type        = bool
  default     = false
  description = "Delete all objects from the bucket  so that the bucket can be destroyed without error (e.g. `true` or `false`)"
}

variable "bucket_domain_format" {
  type        = string
  default     = "%s.s3.amazonaws.com"
  description = "Format of bucket domain name"
}

variable "compress" {
  type        = bool
  default     = false
  description = "Compress content for web requests that include Accept-Encoding: gzip in the request header"
}

variable "is_ipv6_enabled" {
  type        = bool
  default     = true
  description = "State of CloudFront IPv6"
}

variable "default_root_object" {
  type        = string
  default     = "index.html"
  description = "Object that CloudFront return when requests the root URL"
}

variable "comment" {
  type        = string
  default     = ""
  description = "Comment for the origin access identity"
}

variable "log_include_cookies" {
  type        = bool
  default     = false
  description = "Include cookies in access logs"
}

variable "log_prefix" {
  type        = string
  default     = "cloudfront"
  description = "Path of logs in S3 bucket"
}

variable "log_standard_transition_days" {
  description = "Number of days to persist in the standard storage tier before moving to the glacier tier"
  default     = 30
}

variable "log_glacier_transition_days" {
  description = "Number of days after which to move the data to the glacier storage tier"
  default     = 60
}

variable "log_expiration_days" {
  description = "Number of days after which to expunge the objects"
  default     = 90
}

variable "forward_query_string" {
  type        = bool
  default     = false
  description = "Forward query strings to the origin that is associated with this cache behavior"
}

variable "cors_allowed_headers" {
  type        = list(string)
  default     = ["*"]
  description = "List of allowed headers for S3 bucket"
}

variable "cors_allowed_methods" {
  type        = list(string)
  default     = ["GET"]
  description = "List of allowed methods (e.g. GET, PUT, POST, DELETE, HEAD) for S3 bucket"
}

variable "cors_allowed_origins" {
  type        = list(string)
  default     = []
  description = "List of allowed origins (e.g. example.com, test.com) for S3 bucket"
}

variable "cors_expose_headers" {
  type        = list(string)
  default     = ["ETag"]
  description = "List of expose header in the response for S3 bucket"
}

variable "cors_max_age_seconds" {
  default     = 3600
  description = "Time in seconds that browser can cache the response for S3 bucket"
}

variable "forward_cookies" {
  type        = string
  default     = "none"
  description = "Time in seconds that browser can cache the response for S3 bucket"
}

variable "forward_header_values" {
  type        = list(string)
  description = "A list of whitelisted header values to forward to the origin"
  default     = ["Access-Control-Request-Headers", "Access-Control-Request-Method", "Origin"]
}

variable "price_class" {
  type        = string
  default     = "PriceClass_100"
  description = "Price class for this distribution: `PriceClass_All`, `PriceClass_200`, `PriceClass_100`"
}

variable "viewer_protocol_policy" {
  type        = string
  description = "allow-all, redirect-to-https"
  default     = "redirect-to-https"
}

variable "allowed_methods" {
  type        = list(string)
  default     = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
  description = "List of allowed methods (e.g. GET, PUT, POST, DELETE, HEAD) for AWS CloudFront"
}

variable "cached_methods" {
  type        = list(string)
  default     = ["GET", "HEAD"]
  description = "List of cached methods (e.g. GET, PUT, POST, DELETE, HEAD)"
}

variable "default_ttl" {
  default     = 60
  description = "Default amount of time (in seconds) that an object is in a CloudFront cache"
}

variable "min_ttl" {
  default     = 0
  description = "Minimum amount of time that you want objects to stay in CloudFront caches"
}

variable "max_ttl" {
  default     = 31536000
  description = "Maximum amount of time (in seconds) that an object is in a CloudFront cache"
}

variable "trusted_signers" {
  type        = list(string)
  default     = []
  description = "The AWS accounts, if any, that you want to allow to create signed URLs for private content. 'self' is acceptable."
}

variable "geo_restriction_type" {
  # e.g. "whitelist"
  default     = "none"
  description = "Method that use to restrict distribution of your content by country: `none`, `whitelist`, or `blacklist`"
  type        = string
}

variable "geo_restriction_locations" {
  type = list(string)

  # e.g. ["US", "CA", "GB", "DE"]
  default     = []
  description = "List of country codes for which  CloudFront either to distribute content (whitelist) or not distribute your content (blacklist)"
}

variable "parent_zone_id" {
  type        = string
  default     = ""
  description = "ID of the hosted zone to contain this record  (or specify `parent_zone_name`)"
}

variable "parent_zone_name" {
  type        = string
  default     = ""
  description = "Name of the hosted zone to contain this record (or specify `parent_zone_id`)"
}

variable "null" {
  description = "an empty string"
  default     = ""
}

variable "static_s3_bucket" {
  type    = string
  default = "aws-cli"

  description = <<DOC
aws-cli is a bucket owned by amazon that will perminantly exist.
It allows for the data source to be called during the destruction process without failing.
It doesn't get used for anything else, this is a safe workaround for handling the fact that
if a data source like the one `aws_s3_bucket.selected` gets an error, you can't continue the terraform process
which also includes the 'destroy' command, where is doesn't even need this data source!
Don't change this bucket name, it's a variable so that we can provide this description.
And this works around a problem that is an edge case.
DOC
}

variable "custom_error_response" {
  # http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/custom-error-pages.html#custom-error-pages-procedure
  # https://www.terraform.io/docs/providers/aws/r/cloudfront_distribution.html#custom-error-response-arguments
  type = list(object({
    error_caching_min_ttl = string
    error_code            = string
    response_code         = string
    response_page_path    = string
  }))

  description = "List of one or more custom error response element maps"
  default     = []
}

variable "lambda_function_association" {
  type = list(object({
    event_type   = string
    include_body = bool
    lambda_arn   = string
  }))

  description = "A config block that triggers a lambda function with specific actions"
  default     = []
}

variable "web_acl_id" {
  type        = string
  default     = ""
  description = "ID of the AWS WAF web ACL that is associated with the distribution"
}

variable "wait_for_deployment" {
  type        = bool
  default     = true
  description = "When set to 'true' the resource will wait for the distribution status to change from InProgress to Deployed"
}

variable "sse_algorithm" {
  type        = string
  default     = "AES256"
  description = "The server-side encryption algorithm to use. Valid values are `AES256` and `aws:kms`"
}

variable "kms_master_key_arn" {
  type        = string
  default     = ""
  description = "The AWS KMS master key ARN used for the `SSE-KMS` encryption. This can only be used when you set the value of `sse_algorithm` as `aws:kms`. The default aws/s3 AWS KMS master key is used if this element is absent while the `sse_algorithm` is `aws:kms`"
}

variable "enable_security_headers" {
  type        = bool
  default     = true
  description = "Enables creation and attachment of origin-responce edge lambda to add security headers"
}

variable nodejs_security_header_code {
  type        = string
  default     = <<EOF
'use strict';
exports.handler = (event, context, callback) => {

    //Get contents of response
    const response = event.Records[0].cf.response;
    const headers = response.headers;

    //Set new headers 
    headers['strict-transport-security'] = [{
        key: 'Strict-Transport-Security',
        value: 'max-age=63072000; includeSubdomains; preload'
    }];
    headers['x-frame-options'] = [{
        key: 'X-Frame-Options',
        value: 'DENY'
    }];
    headers['content-security-policy'] = [{
        key: 'Content-Security-Policy',
        value: "frame-ancestors 'none'"
    }];

    //Return modified response
    callback(null, response);
};
EOF
  description = "Additional code to be injected into the origin-responce edge lambda"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_cloudfront_origin_access_identity" "default" {
  comment = local.module_prefix
}

data "aws_iam_policy_document" "origin" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::$${bucket_name}$${origin_path}*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.default.iam_arn]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::$${bucket_name}"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.default.iam_arn]
    }
  }
}

data "template_file" "default" {
  template = data.aws_iam_policy_document.origin.json

  vars = {
    origin_path = coalesce(var.origin_path, "/")
    bucket_name = local.bucket
  }
}

resource "aws_s3_bucket_policy" "default" {
  bucket = local.bucket
  policy = data.template_file.default.rendered
}

data "aws_region" "current" {
}

resource "aws_s3_bucket" "origin" {
  count         = signum(length(var.origin_bucket)) == 1 ? 0 : 1
  bucket        = local.module_prefix
  acl           = "private"
  tags          = local.tags
  force_destroy = var.origin_force_destroy
  region        = data.aws_region.current.name

  cors_rule {
    allowed_headers = var.cors_allowed_headers
    allowed_methods = var.cors_allowed_methods
    allowed_origins = sort(
      distinct(compact(concat(var.cors_allowed_origins, var.aliases, var.external_aliases))),
    )
    expose_headers  = var.cors_expose_headers
    max_age_seconds = var.cors_max_age_seconds
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = var.sse_algorithm
        kms_master_key_id = var.kms_master_key_arn
      }
    }
  }
}

module "logs" {
  source                   = "git::https://github.com/cloudposse/terraform-aws-s3-log-storage.git?ref=tags/0.5.0"
  namespace                = ""
  stage                    = ""
  name                     = local.module_prefix
  delimiter                = var.delimiter
  attributes               = compact(concat(var.attributes, ["logs"]))
  tags                     = local.tags
  lifecycle_prefix         = var.log_prefix
  standard_transition_days = var.log_standard_transition_days
  glacier_transition_days  = var.log_glacier_transition_days
  expiration_days          = var.log_expiration_days
  force_destroy            = var.origin_force_destroy
}


data "aws_s3_bucket" "selected" {
  bucket = local.bucket == "" ? var.static_s3_bucket : local.bucket
}

locals {
  bucket = join(
    "",
    compact(
      concat([var.origin_bucket], concat([""], aws_s3_bucket.origin.*.id)),
    ),
  )

  bucket_domain_name = var.use_regional_s3_endpoint ? format(
    "%s.s3-%s.amazonaws.com",
    local.bucket,
    data.aws_s3_bucket.selected.region,
  ) : format(var.bucket_domain_format, local.bucket)
}

resource "aws_cloudfront_distribution" "default" {
  enabled             = var.create
  is_ipv6_enabled     = var.is_ipv6_enabled
  comment             = format("%s %s", var.desc_prefix, var.comment)
  default_root_object = var.default_root_object
  price_class         = var.price_class
  depends_on          = [aws_s3_bucket.origin]

  logging_config {
    include_cookies = var.log_include_cookies
    bucket          = module.logs.bucket_domain_name
    prefix          = var.log_prefix
  }

  aliases = sort(
    distinct(compact(concat(var.aliases, var.external_aliases))),
  )
  # aliases = var.aliases

  origin {
    domain_name = local.bucket_domain_name
    origin_id   = local.module_prefix
    origin_path = var.origin_path

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.default.cloudfront_access_identity_path
    }
  }

  viewer_certificate {
    acm_certificate_arn            = var.acm_certificate_arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = var.minimum_protocol_version
    cloudfront_default_certificate = var.acm_certificate_arn == "" ? true : false
  }

  default_cache_behavior {
    allowed_methods  = var.allowed_methods
    cached_methods   = var.cached_methods
    target_origin_id = local.module_prefix
    compress         = var.compress
    trusted_signers  = var.trusted_signers

    forwarded_values {
      query_string = var.forward_query_string
      headers      = var.forward_header_values

      cookies {
        forward = var.forward_cookies
      }
    }

    viewer_protocol_policy = var.viewer_protocol_policy
    default_ttl            = var.default_ttl
    min_ttl                = var.min_ttl
    max_ttl                = var.max_ttl

    dynamic "lambda_function_association" {
      for_each = var.lambda_function_association
      content {
        event_type   = lambda_function_association.value.event_type
        include_body = lookup(lambda_function_association.value, "include_body", null)
        lambda_arn   = lambda_function_association.value.lambda_arn
      }
    }

    dynamic "lambda_function_association" {
      for_each = var.create && var.enable_security_headers ? ["1"] : []
      content {
        event_type   = "origin-response"
        include_body = false
        lambda_arn   = aws_lambda_function.hsts[0].qualified_arn
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction_type
      locations        = var.geo_restriction_locations
    }
  }

  dynamic "custom_error_response" {
    for_each = var.custom_error_response
    content {
      error_caching_min_ttl = lookup(custom_error_response.value, "error_caching_min_ttl", null)
      error_code            = custom_error_response.value.error_code
      response_code         = lookup(custom_error_response.value, "response_code", null)
      response_page_path    = lookup(custom_error_response.value, "response_page_path", null)
    }
  }

  web_acl_id          = var.web_acl_id
  wait_for_deployment = var.wait_for_deployment

  tags = local.tags
}

module "dns" {
  source           = "git::https://github.com/cloudposse/terraform-aws-route53-alias.git?ref=tags/0.3.0"
  enabled          = var.create && length(var.parent_zone_id) > 0 || length(var.parent_zone_name) > 0 ? true : false
  aliases          = var.aliases
  parent_zone_id   = var.parent_zone_id
  parent_zone_name = var.parent_zone_name
  target_dns_name  = aws_cloudfront_distribution.default.domain_name
  target_zone_id   = aws_cloudfront_distribution.default.hosted_zone_id
}

resource "aws_iam_role" "hsts" {
  count = var.create && var.enable_security_headers ? 1 : 0
  name  = join(var.delimiter, [local.module_prefix, "hsts", "header"])

  description        = "${var.desc_prefix} Lambda role for s3 cdn HSTS header attachment"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "edgelambda.amazonaws.com",
          "lambda.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags = local.tags
}

resource "aws_iam_role_policy" "hsts" {
  count = var.create && var.enable_security_headers ? 1 : 0
  name  = join(var.delimiter, [local.module_prefix, "hsts", "header"])
  role  = aws_iam_role.hsts[0].id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
EOF
}

data "archive_file" "hsts" {
  type        = "zip"
  output_path = "./dist/hsts.zip"
  source {
    content  = var.nodejs_security_header_code
    filename = "index.js"
  }
}

resource "aws_lambda_function" "hsts" {
  count         = var.create && var.enable_security_headers ? 1 : 0
  filename      = data.archive_file.hsts.output_path
  function_name = join(var.delimiter, [local.module_prefix, "hsts"])
  role          = aws_iam_role.hsts[0].arn
  handler       = "index.handler"
  description   = "Blueprint for modifying CloudFront response header implemented in NodeJS."

  source_code_hash = data.archive_file.hsts.output_base64sha256

  runtime     = "nodejs12.x"
  timeout     = 1
  memory_size = 128

  tags = local.tags

  tracing_config {
    mode = "PassThrough"
  }
  publish = true
}

# ----------------------------------------------------------------------------------------------------------------------
# Outputs
# ----------------------------------------------------------------------------------------------------------------------

output "cf_id" {
  value       = aws_cloudfront_distribution.default.id
  description = "ID of AWS CloudFront distribution"
}

output "cf_arn" {
  value       = aws_cloudfront_distribution.default.arn
  description = "ARN of AWS CloudFront distribution"
}

output "cf_status" {
  value       = aws_cloudfront_distribution.default.status
  description = "Current status of the distribution"
}

output "cf_domain_name" {
  value       = aws_cloudfront_distribution.default.domain_name
  description = "Domain name corresponding to the distribution"
}

output "cf_etag" {
  value       = aws_cloudfront_distribution.default.etag
  description = "Current version of the distribution's information"
}

output "cf_hosted_zone_id" {
  value       = aws_cloudfront_distribution.default.hosted_zone_id
  description = "CloudFront Route 53 zone ID"
}

output "s3_bucket" {
  value       = local.bucket
  description = "Name of S3 bucket"
}

output "s3_bucket_domain_name" {
  value       = local.bucket_domain_name
  description = "Domain of S3 bucket"
}
