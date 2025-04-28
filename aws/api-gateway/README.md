<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_api_gateway_base_path_mapping.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_base_path_mapping) | resource |
| [aws_api_gateway_deployment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_deployment) | resource |
| [aws_api_gateway_domain_name.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_domain_name) | resource |
| [aws_api_gateway_domain_name_access_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_domain_name_access_association) | resource |
| [aws_api_gateway_method_settings.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method_settings) | resource |
| [aws_api_gateway_rest_api.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api) | resource |
| [aws_api_gateway_rest_api_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api_policy) | resource |
| [aws_api_gateway_stage.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_stage) | resource |
| [aws_lambda_permission.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_route53_record.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_endpoint.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | The AWS Account ID that contains the calling entity | `string` | `""` | no |
| <a name="input_authorizers"></a> [authorizers](#input\_authorizers) | The authorizers to use for the API Gateway. The key is the type of the authorizer and the value is the configuaration. Supported types are 'cognito'. | `map(any)` | `{}` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region to deploy module into | `string` | `"us-east-1"` | no |
| <a name="input_create"></a> [create](#input\_create) | Set to false to prevent the module from creating any resources | `bool` | `true` | no |
| <a name="input_delimiter"></a> [delimiter](#input\_delimiter) | Delimiter to be used between `namespace`, `environment`, `stage`, `name` | `string` | `"-"` | no |
| <a name="input_desc_prefix"></a> [desc\_prefix](#input\_desc\_prefix) | The prefix to add to any descriptions attached to resources | `string` | `"Gravicore:"` | no |
| <a name="input_domain"></a> [domain](#input\_domain) | The domain name and SSL certificate to use for the API Gateway. If not provided, the API Gateway will have only the stage domain. | <pre>object({<br/>    id   = string<br/>    name = string<br/>    ssl  = string<br/>  })</pre> | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | The isolated environment the module is associated with (e.g. Shared Services `shared`, Application `app`) | `string` | `""` | no |
| <a name="input_environment_prefix"></a> [environment\_prefix](#input\_environment\_prefix) | Concatenation of `namespace` and `environment` | `string` | `""` | no |
| <a name="input_master_account_id"></a> [master\_account\_id](#input\_master\_account\_id) | The Master AWS Account ID that owns the associate AWS account | `string` | `""` | no |
| <a name="input_module_prefix"></a> [module\_prefix](#input\_module\_prefix) | Concatenation of `namespace`, `environment`, `stage` and `name` | `string` | `""` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the module | `string` | `""` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace, which could be your organization abbreviation, client name, etc. (e.g. Gravicore 'grv', HashiCorp 'hc') | `string` | `""` | no |
| <a name="input_paths"></a> [paths](#input\_paths) | The paths to use for the API Gateway. The key is the path and the value is the configuration. The configuration is a map with the following keys: 'lambda' (the ARN of the Lambda function to invoke) and 'authorizers' (a list of authorizers to use for the path). | <pre>map(map(object({<br/>    lambda      = optional(string, "")<br/>    authorizers = optional(list(string), [])<br/>  })))</pre> | `{}` | no |
| <a name="input_private"></a> [private](#input\_private) | The VPC and subnets to use for the API Gateway. If not provided, the API Gateway will be public. | <pre>object({<br/>    vpc     = string<br/>    subnets = list(string)<br/>    cidrs   = optional(list(string), ["0.0.0.0/0"])<br/>  })</pre> | `null` | no |
| <a name="input_repository"></a> [repository](#input\_repository) | The repository where the code referencing the module is stored | `string` | `""` | no |
| <a name="input_stage"></a> [stage](#input\_stage) | The development stage (i.e. `dev`, `stg`, `prd`) | `string` | `""` | no |
| <a name="input_stage_prefix"></a> [stage\_prefix](#input\_stage\_prefix) | Concatenation of `namespace`, `environment` and `stage` | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional map of tags (e.g. business\_unit, cost\_center) | `map(string)` | `{}` | no |
| <a name="input_terraform_module"></a> [terraform\_module](#input\_terraform\_module) | The owner and name of the Terraform module | `string` | `"gravicore/terraform-gravicore-modules/aws/api-gateway"` | no |
| <a name="input_throttle"></a> [throttle](#input\_throttle) | The throttle settings for the API Gateway. The default is 10 requests per second and 20 burst capacity. | <pre>object({<br/>    rate  = optional(number, 10)<br/>    burst = optional(number, 20)<br/>  })</pre> | `{}` | no |
| <a name="input_timeout"></a> [timeout](#input\_timeout) | The timeout for the API Gateway in seconds. The default is 29 seconds. | `number` | `29` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_api-gateway"></a> [api-gateway](#output\_api-gateway) | The API Gateway outputs |
<!-- END_TF_DOCS -->

## Public API Gateway

```terraform
module "api-gateway" {
  source  = "./api-gateway"
  name    = "api-gateway"
  paths = {
    "/users" = {
      post = {
        lambda = "arn:aws:lambda:us-east-1:123456789012:function:users"
      }
    }
  }
}
```

## Private API Gateway

```terraform
module "api-gateway" {
  source  = "./api-gateway"
  name    = "api-gateway"
  private = {
    vpc     = "my-vpc-id"
    subnets = ["subnet-a", "subnet-b"]
    cidrs   = ["12.0.0.0/16"]
  }
  paths = {
    "/users" = {
      post = {
        lambda = "arn:aws:lambda:us-east-1:123456789012:function:users"
      }
    }
  }
}
```

## Custom Domain API Gateway

```terraform
module "api-gateway" {
  source  = "./api-gateway"
  name    = "api-gateway"
  domain = {
    id   = "HAU2556S"
    name = "example.com"
    ssl  = "arn:aws:acm:us-east-1:123456789012:certificate/abcd1234-5678-90ef-ghij-1234567890ab"
  }
  paths = {
    "/users" = {
      post = {
        lambda = "arn:aws:lambda:us-east-1:123456789012:function:users"
      }
    }
  }
}
```

## Cognito Authorization API Gateway

```terraform
module "api-gateway" {
  source  = "./api-gateway"
  name    = "api-gateway"
  authorizers = {
    cognito = "pool-123abc"
  }
  paths = {
    "/users" = {
      post = {
        lambda      = "arn:aws:lambda:us-east-1:123456789012:function:users"
        authorizers = ["cognito"]
      }
    }
  }
}
```
