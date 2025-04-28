<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_ecs_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_ecs_cluster_capacity_providers.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster_capacity_providers) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | The AWS Account ID that contains the calling entity | `string` | `""` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region to deploy module into | `string` | `"us-east-1"` | no |
| <a name="input_create"></a> [create](#input\_create) | Set to false to prevent the module from creating any resources | `bool` | `true` | no |
| <a name="input_delimiter"></a> [delimiter](#input\_delimiter) | Delimiter to be used between `namespace`, `environment`, `stage`, `name` | `string` | `"-"` | no |
| <a name="input_desc_prefix"></a> [desc\_prefix](#input\_desc\_prefix) | The prefix to add to any descriptions attached to resources | `string` | `"Gravicore:"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | The isolated environment the module is associated with (e.g. Shared Services `shared`, Application `app`) | `string` | `""` | no |
| <a name="input_environment_prefix"></a> [environment\_prefix](#input\_environment\_prefix) | Concatenation of `namespace` and `environment` | `string` | `""` | no |
| <a name="input_master_account_id"></a> [master\_account\_id](#input\_master\_account\_id) | The Master AWS Account ID that owns the associate AWS account | `string` | `""` | no |
| <a name="input_module_prefix"></a> [module\_prefix](#input\_module\_prefix) | Concatenation of `namespace`, `environment`, `stage` and `name` | `string` | `""` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the module | `string` | `"ecr"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace, which could be your organization abbreviation, client name, etc. (e.g. Gravicore 'grv', HashiCorp 'hc') | `string` | `""` | no |
| <a name="input_repository"></a> [repository](#input\_repository) | The repository where the code referencing the module is stored | `string` | `""` | no |
| <a name="input_stage"></a> [stage](#input\_stage) | The development stage (i.e. `dev`, `stg`, `prd`) | `string` | `""` | no |
| <a name="input_stage_prefix"></a> [stage\_prefix](#input\_stage\_prefix) | Concatenation of `namespace`, `environment` and `stage` | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional map of tags (e.g. business\_unit, cost\_center) | `map(string)` | `{}` | no |
| <a name="input_task"></a> [task](#input\_task) | the configuration shared by all tasks in the cluster | <pre>object({<br/>    certificate_arn    = optional(string, "")<br/>    execution_role_arn = optional(string, "")<br/>    role_arn           = optional(string, "")<br/>    security_group_ids = optional(list(string), [])<br/>    subnet_ids         = optional(list(string), [])<br/>    vpc_id             = optional(string, "")<br/>    zone_id            = optional(string, "")<br/>    zone_name          = optional(string, "")<br/>  })</pre> | `{}` | no |
| <a name="input_terraform_module"></a> [terraform\_module](#input\_terraform\_module) | The owner and name of the Terraform module | `string` | `"gravicore/terraform-gravicore-modules/aws/ecr"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_name"></a> [name](#output\_name) | ---------------------------------------------------------------------------------------------------------------------- OUTPUTS ---------------------------------------------------------------------------------------------------------------------- |
| <a name="output_task"></a> [task](#output\_task) | n/a |
<!-- END_TF_DOCS -->