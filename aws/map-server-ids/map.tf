# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "mpe_id" {
  type        = string
  default     = ""
  description = "MPE ID used for the map35 cloudformation stack"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

data "template_file" "server_ids" {
  template = <<STACK
  {
 	"AWSTemplateFormatVersion": "2010-09-09",

 	"Description": "This template uploads a list of on-premise servers to AWS Migration Hub, generates Originating IDs, and exports the generated results. Contact your AWS account team for questions/issues.",

 	"Metadata": {},

 	"Parameters": {
 		"MPE": {
 			"Type": "String",
 			"Default": "e.g.MPE11111",
 			"Description": "Contact your AWS account team, or check your MAP agreement.",
 			"MinLength": 8,
 			"ConstraintDescription": "Required field"
 		},
 		"S3Region": {
 			"Type": "String",
 			"Description": "Select a region for inventroy upload to AWS Migration Hub.",
 			"MinLength": 1,
 			"ConstraintDescription": "Required field",
 			"AllowedValues": ["us-east-1", "us-west-2", "ap-northeast-1", "ap-southeast-2", "eu-central-1", "eu-west-1", "eu-west-2"]
 		}
 	},

 	"Mappings": {},

 	"Conditions": {},

 	"Resources": {

 		"MyS3Bucket": {
 			"DependsOn": "MyInvokeLambdaPermission",
 			"Type": "AWS::S3::Bucket",
 			"DeletionPolicy": "Delete",
 			"Properties": {
 				"BucketName": {
 					"Fn::Sub": "migration-hub-inventory-bucket-$\u0024{AWS::AccountId}"
 				},
 				"NotificationConfiguration": {
 					"LambdaConfigurations": [{
 						"Event": "s3:ObjectCreated:Put",
 						"Filter": {
 							"S3Key": {
 								"Rules": [{
 										"Name": "prefix",
 										"Value": "Upload-Your-Inventory-In-This-Folder/"
 									},
 									{
 										"Name": "suffix",
 										"Value": ".csv"
 									}
 								]
 							}
 						},
 						"Function": {
 							"Fn::GetAtt": ["MyLambdaFunction", "Arn"]
 						}
 					}]
 				}
 			}
 		},

 		"MyIAMRole": {
 			"Type": "AWS::IAM::Role",
 			"Properties": {
 				"AssumeRolePolicyDocument": {
 					"Version": "2012-10-17",
 					"Statement": [{
 						"Effect": "Allow",
 						"Principal": {
 							"Service": [
 								"lambda.amazonaws.com"
 							]
 						},
 						"Action": [
 							"sts:AssumeRole"
 						]
 					}]
 				},
 				"Description": "IAM Role for lambda function",
 				"ManagedPolicyArns": [
 					"arn:aws:iam::aws:policy/AWSLambdaExecute",
 					"arn:aws:iam::aws:policy/AWSApplicationDiscoveryServiceFullAccess"
 				],
 				"Path": "/",
 				"Policies": [],
 				"Tags": []
 			}
 		},

 		"MyLambdaFunction": {
 			"Type": "AWS::Lambda::Function",
 			"Properties": {
 				"Code": {
 					"S3Bucket": {
 						"Fn::Join": ["", ["map-automation-", {
 							"Ref": "S3Region"
 						}]]
 					},
 					"S3Key": "lambda_function_v2.zip"
 				},
 				"Description": "Lambda function for MigrationHub automation.",
 				"Environment": {
 					"Variables": {
 						"AWS_MIGRATION_PROJECT_ID": {
 							"Ref": "MPE"
 						},
 						"S3_REGION": {
 							"Ref": "S3Region"
 						},
 						"AWS_ACCOUNT_ID": {
 							"Fn::Sub": "$\u0024{AWS::AccountId}"
 						}
 					}
 				},
 				"Handler": "lambda_function_v2.lambda_handler",
 				"MemorySize": 128,
 				"Role": {
 					"Fn::GetAtt": [
 						"MyIAMRole",
 						"Arn"
 					]
 				},
 				"Runtime": "python3.7",
 				"Timeout": 120
 			}
 		},

 		"MyInvokeLambdaPermission": {
 			"Type": "AWS::Lambda::Permission",
 			"Properties": {
 				"Action": "lambda:InvokeFunction",
 				"FunctionName": {
 					"Fn::GetAtt": [
 						"MyLambdaFunction",
 						"Arn"
 					]
 				},
 				"Principal": "s3.amazonaws.com",
 				"SourceAccount": {
 					"Ref": "AWS::AccountId"
 				},
 				"SourceArn": {
 					"Fn::Sub": "arn:aws:s3:::migration-hub-inventory-bucket-$\u0024{AWS::AccountId}"
 				}
 			}
 		},

 		"CreateInputFolderLambdaFunction": {
 			"Type": "AWS::Lambda::Function",
 			"Properties": {
 				"Code": {
 					"S3Bucket": {
 						"Fn::Join": ["", ["map-automation-", {
 							"Ref": "S3Region"
 						}]]
 					},
 					"S3Key": "folder_creation_lambda_function_v2.zip"
 				},
 				"Description": "Lambda function for Input folder creation.",
 				"Environment": {
 					"Variables": {
 						"INPUT_BUCKET_NAME": {
 							"Fn::Sub": "migration-hub-inventory-bucket-$\u0024{AWS::AccountId}"
 						},
 						"INPUT_FOLDER": "Upload-Your-Inventory-In-This-Folder"
 					}
 				},
 				"Handler": "folder_creation_lambda_function_v2.lambda_handler",
 				"MemorySize": 128,
 				"Role": {
 					"Fn::GetAtt": [
 						"MyIAMRole",
 						"Arn"
 					]
 				},
 				"Runtime": "python3.7",
 				"Timeout": 60
 			}
 		},

 		"InvokeLambda": {
 			"Type": "Custom::InvokeLambda",
 			"Version": "1.0",
 			"Properties": {
 				"ServiceToken": {
 					"Fn::GetAtt": ["CreateInputFolderLambdaFunction", "Arn"]
 				}
 			}
 		}

 	},

 	"Outputs": {

 		"BucketName": {
 			"Value": {
 				"Ref": "MyS3Bucket"
 			},
 			"Export": {
 				"Name": "map-automation-migration-hub-in-out-s3-bucket"
 			},
 			"Description": "Name of the Amazon S3 bucket created."

 		},

 		"RoleName": {
 			"Value": {
 				"Ref": "MyIAMRole"
 			},
 			"Description": "Name of the IAM Role created."
 		},

 		"LambdaFunctionName": {
 			"Value": {
 				"Ref": "MyLambdaFunction"
 			},
 			"Description": "Name of the Lambda function created."
 		}
 	}
 }
  STACK
}
resource "aws_cloudformation_stack" "map35" {

  capabilities = ["CAPABILITY_IAM"]

  count = var.create ? 1 : 0
  name  = join(var.delimiter, [local.module_prefix])

  template_body = data.template_file.server_ids.rendered

  parameters = {
    MPE      = var.mpe_id
    S3Region = var.aws_region
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# Outputs
# ----------------------------------------------------------------------------------------------------------------------

output "cloudtrail_stack_outputs" {
  value       = aws_cloudformation_stack.map35.*.outputs
  description = ""
}
