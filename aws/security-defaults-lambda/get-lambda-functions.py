#!/usr/bin/env python
import subprocess
import json
import sys, os, shutil
from types import SimpleNamespace

# CLI Arguments
if len(sys.argv) != 2:
    raise ValueError('Usage: ./get-lambda-functions.py [aws-profile] \n \
        ie. ./get-lambda-functions.py default')

# Set Arguments
aws_profile = sys.argv[1]

# Get All Lambdas Associated to AWS Profile
lambdas = json.loads(subprocess.check_output("aws lambda list-functions --profile " + aws_profile, shell=True), \
    object_hook=lambda d: SimpleNamespace(**d))

# Debug
print ("Generating terragrunt-hcl files")

# Loop Through Regions
for fun in lambdas.Functions:

    # If doesn't have a default VPC
    if ((hasattr(fun, 'VpcConfig') and fun.VpcConfig.VpcId == "") or not hasattr(fun, 'VpcConfig')):
         print ('"' + str(fun.FunctionName) + '",')