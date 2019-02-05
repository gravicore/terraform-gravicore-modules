<a href="http://gravicore.io"><img src="https://docs.google.com/uc?id=1w7JERRtb2FlhqTE5KERM1Yu3bImmfypP" alt="Gravicore" width="400"></a>

# terraform-gravicore-modules ![Build Status](https://img.shields.io/badge/build-undefined-lightgrey.svg) [![Latest Release](https://img.shields.io/github/release/gravicore/terraform-gravicore-modules.svg)](https://github.com/gravicore/terraform-gravicore-modules/releases/latest)

This is a collection of reusable Terraform modules for Gravicore's cloud automation platform.

## Modules

### AWS

| Module                                       | Description                                                                                                                                                                                              |
| :------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [Account](aws/account)                       | A collection of modules for bootstrapping an [AWS Organization](https://aws.amazon.com/organizations/) and associated children accounts.                                                                 |
| [Shared VPC](aws/shared-vpc)                 | A secure, dual-AZ Shared Services VPC with public subnets, private subnets, Internet Gateway and shared Directory Service.                                                                               |
| [Spoke VPC](aws/spoke-vpc)                   | A secure, dual-AZ Spoke VPC with public subnets, private subnets and an Internet Gateway.                                                                                                                |
| [Aviatrix](aws/aviatrix)                     | A collection of modules for deploying [Aviatrix](https://www.aviatrix.com)'s global transit hub solution.                                                                                                |
| [Instance Scheduler](aws/instance-scheduler) | A module enabling the configuration of custom start and stop schedules for Amazon EC2 and RDS instances. [Read More](https://aws.amazon.com/answers/infrastructure-management/instance-scheduler/) |

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
