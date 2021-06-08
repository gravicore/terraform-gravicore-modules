#!/usr/bin/env python
import subprocess
import json
import sys, os, shutil
from types import SimpleNamespace

# CLI Arguments
if len(sys.argv) != 2:
    raise ValueError('Usage: ./get-ec2-instances.py [aws-profile] \n \
        ie. ./get-ec2-instances.py default')

# Set Arguments
aws_profile = sys.argv[1]

# Get All EC2 Instances Associated to AWS Profile
reservations = json.loads(subprocess.check_output("aws ec2 describe-instances --profile " + aws_profile, shell=True) , \
    object_hook=lambda d: SimpleNamespace(**d))

# Debug
print ("Getting EC2 Instances")

# Loop Through Reservations
for reservation in reservations.Reservations:

    # Loop Through Instances
    for instance in reservation.Instances:
    
        http_tokens_enabled = "http_tokens_enabled:false"
        # Check if MetaData Options Token is enabled
        if(instance.MetadataOptions.HttpTokens != 'optional'):
            http_tokens_enabled = "http_tokens_enabled:true"

        print ('"' + str(instance.InstanceId) + '",' + http_tokens_enabled)