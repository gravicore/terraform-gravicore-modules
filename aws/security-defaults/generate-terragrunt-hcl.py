#!/usr/bin/env python
import subprocess
import json
import sys, os, shutil
from types import SimpleNamespace

# CLI Arguments
if len(sys.argv) != 6:
    raise ValueError('Usage: ./generate-terragrunt-hcl.py [aws-profile] [stage] [default-security-groups=true|false] [delete-default-vpcs=true|false] [output-dir] \n \
        ie. ./generate-terragrunt-hcl.py default dev true true ./terragrunt/security-defaults')

# Set Arguments
aws_profile = sys.argv[1]
stage = sys.argv[2]
default_sg_groups = sys.argv[3]
delete_default_vpcs = sys.argv[4]
output_dir = sys.argv[5]

# Get All Regions Associated to AWS Profile
regions = json.loads(subprocess.check_output("aws ec2 describe-regions --profile " + aws_profile, shell=True), \
    object_hook=lambda d: SimpleNamespace(**d))

# Debug
print ("Generating terragrunt-hcl files")

# Copy default providers.tf
shutil.copy("templates/providers.tf", output_dir)

# Loop Through Regions
for region in regions.Regions:

    # VPC suffix counter
    vpc_counter = 1

    # Get Next VPC Flag
    get_next_vpc = True

    # Get VPCs
    while (get_next_vpc):

        # If Starting Token Exists
        starting_token = ""
        if ('vpcs' in vars() and hasattr(vpcs, 'NextToken')):
            starting_token = " --starting-token " + vpcs.NextToken

        # Get All VPCs in Regions
        vpcs = json.loads(subprocess.check_output("aws ec2 describe-vpcs --region " + region.RegionName \
            + " --profile " + aws_profile + starting_token, shell=True), object_hook=lambda d: SimpleNamespace(**d))

        # If Next Token Doesn't Exists
        if not (hasattr(vpcs, 'NextToken')):
            get_next_vpc = False

        # Loop Through VPCs (could be more than one due to EC2-Classic)
        for vpc in vpcs.Vpcs:
            print("Generating Hcl for Region: " + region.RegionName + ", VPC: " + vpc.VpcId)

            # Create Dirs
            stage_dir = output_dir + "/" + region.RegionName + "/default-vpc-" + str(vpc_counter)
            os.makedirs(stage_dir, exist_ok=True)

            # Copy Templates
            shutil.copy("templates/stage.env.tfvars", stage_dir + "/stage." + stage + ".tfvars")
            shutil.copy("templates/terragrunt.hcl", stage_dir)

            # Bug in possibly lower version of terraform on ap-northeast-3
            skip_region_validation = "false"
            if region.RegionName == 'ap-northeast-3':
                skip_region_validation = "true"

            # Get delete default vpc setting from argument
            set_delete_default_vpcs = delete_default_vpcs

            # Do not delete non-default VPC by default
            if not vpc.IsDefault:
                set_delete_default_vpcs = "false"

            # Token replacement
            f = open(stage_dir + "/stage." + stage + ".tfvars", "rt")
            data = f.read()
            data = data.replace("###VPC_ID###", vpc.VpcId)
            data = data.replace("###AWS_REGION###", region.RegionName)
            data = data.replace("###SKIP_REGION_VALIDATION###", skip_region_validation)
            data = data.replace("###DEFAULT_SECURITY_GROUP_RULES###", default_sg_groups)
            data = data.replace("###DELETE_DEFAULT_VPCSs###", set_delete_default_vpcs)
            
            f.close()
            f = open(stage_dir + "/stage." + stage + ".tfvars", "wt")
            f.write(data)
            f.close()
            vpc_counter += 1
