#!/usr/bin/env python
import subprocess
import json
import sys, os, shutil
from types import SimpleNamespace

# CLI Arguments
if len(sys.argv) != 4:
    raise ValueError('Usage: ./generate-terragrunt-hcl.py [aws-profile] [stage] [output-dir] \n \
        ie. ./generate-terragrunt-hcl.py default dev ./terragrunt/security-defaults')

# Set Arguments
aws_profile = sys.argv[1]
stage = sys.argv[2]
output_dir = sys.argv[3]

# Get All Regions Associated to AWS Profile
regions = json.loads(subprocess.check_output("aws ec2 describe-regions --profile " + aws_profile, shell=True), \
    object_hook=lambda d: SimpleNamespace(**d))

# Debug
print ("Generating terragrunt-hcl files")

# Copy default providers.tf
shutil.copy("templates/providers.tf", output_dir)

# Loop Through Regions
for region in regions.Regions:
    vpcs = json.loads(subprocess.check_output("aws ec2 describe-vpcs --region " + region.RegionName \
        + " --profile " + aws_profile, shell=True), object_hook=lambda d: SimpleNamespace(**d))
    
    # Loop Through VPCs (could be more than one due to EC2-Classic)
    vpc_counter = 1
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

        # Token replacement
        f = open(stage_dir + "/stage." + stage + ".tfvars", "rt")
        data = f.read()
        data = data.replace("###VPC_ID###", vpc.VpcId)
        data = data.replace("###AWS_REGION###", region.RegionName)
        data = data.replace("###SKIP_REGION_VALIDATION###", skip_region_validation)
        f.close()
        f = open(stage_dir + "/stage." + stage + ".tfvars", "wt")
        f.write(data)
        f.close()
        vpc_counter += 1
