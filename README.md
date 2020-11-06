<a href="http://gravicore.io"><img src="https://docs.google.com/uc?id=1w7JERRtb2FlhqTE5KERM1Yu3bImmfypP" alt="Gravicore" width="400"></a>

# terraform-gravicore-modules [![Latest Release](https://img.shields.io/github/release/gravicore/terraform-gravicore-modules.svg)](https://github.com/gravicore/terraform-gravicore-modules/releases/latest) ![Build Status](https://img.shields.io/github/workflow/status/gravicore/terraform-gravicore-modules/Terraform)

This is a collection of reusable Terraform modules for Gravicore's cloud automation platform.

## Modules

### AWS

| Module                                               | Description                                                                                                                                                                                                                                                                                                                                |
| :--------------------------------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [Account](aws/account)                               | A set of IAM policies to set the password policy and alias for an account. Also allows for optional access to Gravicore through SSO.                                                                                                                                                                                                       |
| [Account Roles](aws/account-roles)                   | A collection of IAM policies, groups and roles for providing access to any accounts in the Organization.                                                                                                                                                                                                                                   |
| [ACM](aws/acm)                                       | A module for deploying environment based auto-rotating wildcard certificates using [AWS Certificate Manager](https://aws.amazon.com/certificate-manager/).                                                                                                                                                                                 |
| [ALB](aws/alb)                                       | A module enabling the deployment of [AWS Elastic Load Balancing (Application Load Balancer)](https://aws.amazon.com/elasticloadbalancing//) solutions. Best suited for HTTP/HTTPS traffic or microservice/container applications.                                                                                                          |
| [Aviatrix](aws/aviatrix)                             | A collection of modules for deploying [Aviatrix](https://www.aviatrix.com)'s [Next-Gen Transit Network for AWS](https://www.aviatrix.com/solutions/next-gen-transit-network-aws.php), [User VPN](https://www.aviatrix.com/solutions/user-vpn.php) and [Site to Cloud VPN](https://www.aviatrix.com/solutions/site-to-cloud.php) solutions. |
| [Central Logging](aws/central-logging)               | A collection of modules for deploying resources for centralized logging.                                                                                                                                                                                                                                                                   |
| [Cerberus FTP](aws/cerberus)                         | A module for deploying the infrastructure resources needed for [Cerberus FTP](https://www.cerberusftp.com/).                                                                                                                                                                                                                               |
| [CI/CD](aws/cicd)                                    | A module for deploying an IAM user with access keys to be used as a service account for CICD pipelines.                                                                                                                                                                                                                                    |
| [CodeCommit](aws/codecommit)                         | A module for deploying the infrastructure resources needed for an [AWS CodeCommit](https://aws.amazon.com/codecommit/) repository.                                                                                                                                                                                                         |
| [Cognito](aws/cognito)                               | A module for deploying the infrastructure resources needed for an [Amazon Cognito](https://aws.amazon.com/cognito/) user and identity pool.                                                                                                                                                                                                |
| [Data Transfer](aws/data-transfer)                   | A module for deploying a data transfer solution utilizing [AWS DataSync](https://aws.amazon.com/datasync/) and [AWS Snowball](https://aws.amazon.com/snowball/).                                                                                                                                                                           |
| [Datadog](aws/datadog)                               | A module for deploying a centralized logging solution leveraging [Datadog](https://www.datadoghq.com/).                                                                                                                                                                                                                                    |
| [DNS](aws/dns)                                       | A module for deploying parent DNS services and optional delegated subdomains utilizing [Route53](https://aws.amazon.com/route53/).                                                                                                                                                                                                         |
| [ElastiCache (Redis)](aws/elasticache-redis)         | A module for deploying an in-memory data store utilizing [Amazon ElastiCache for Redis](https://aws.amazon.com/elasticache/redis/) instance.                                                                                                                                                                                               |
| [Instance Scheduler](aws/instance-scheduler)         | A module enabling the configuration of custom start and stop schedules for Amazon EC2 and RDS instances through the deployment of the [AWS Instance Scheduler](https://aws.amazon.com/solutions/instance-scheduler/) solution.                                                                                                             |
| [KMS](aws/kms)                                       | A module enabling default encryption keys for securing different types of data using the [AWS Key Management Service (KMS)](https://aws.amazon.com/kms/).                                                                                                                                                                                  |
| [Organization](aws/organization)                     | A module providing central governance and managenent of a multi-account setup using [AWS Organizations](https://aws.amazon.com/organizations/).                                                                                                                                                                                            |
| [RDS](aws/rds)                                       | A collection of modules for deploying [Amazon Relational Database Service (RDS)](https://aws.amazon.com/rds/) resources.                                                                                                                                                                                                                   |
| [RDS (PostgreSQL)](aws/rds-postgres)                 | A module for deploying [Amazon RDS for PostgreSQL](https://aws.amazon.com/rds/postgresql/) resources.                                                                                                                                                                                                                                      |
| [RDS Replica (PostgreSQL)](aws/rds-postgres-replica) | A module for deploying PostgreSQL focused [Amazon RDS Read Replicas](https://aws.amazon.com/rds/features/read-replicas/) resources.                                                                                                                                                                                                        |
| [SSM Parameters](aws/parameters)                     | A module that supports reading and writing of key/value pairs from the [AWS Systems Manager (SSM) Parameter Store](https://aws.amazon.com/systems-manager/features/#Parameter_Store) service.                                                                                                                                              |
| [VPC](aws/vpc)                                       | A secure, multi-AZ VPC with public subnets, private subnets, Internet Gateway, optional NAT and optional VPC Endpoints utilizing [Amazon Virtual Private Cloud](https://aws.amazon.com/vpc/).                                                                                                                                              |
| [VPC DNS](aws/vpc-dns)                               | A module for deploying environment based delegated DNS zones utilizing [Route53](https://aws.amazon.com/route53/).                                                                                                                                                                                                                         |

## Contributing

### Bug Reports & Feature Requests

Please use the [issue tracker](https://github.com/gravicore/terraform-gravicore-modules/issues) to report any bugs or file feature requests.

## Copyright

Copyright © 2018 [Gravicore, LLC](http://gravicore.io)

## License

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

See [LICENSE](LICENSE) for full details.

    Licensed to the Apache Software Foundation (ASF) under one
    or more contributor license agreements.  See the NOTICE file
    distributed with this work for additional information
    regarding copyright ownership.  The ASF licenses this file
    to you under the Apache License, Version 2.0 (the
    "License"); you may not use this file except in compliance
    with the License.  You may obtain a copy of the License at

      https://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing,
    software distributed under the License is distributed on an
    "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
    KIND, either express or implied.  See the License for the
    specific language governing permissions and limitations
    under the License.

## Trademarks

All other trademarks referenced herein are the property of their respective owners.
