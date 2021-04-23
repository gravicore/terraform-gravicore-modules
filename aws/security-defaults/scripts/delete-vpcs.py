#!/usr/bin/env python
import subprocess
import json
import sys, os, shutil
from types import SimpleNamespace

# CLI Arguments
if len(sys.argv) != 3:
    raise ValueError('Usage: ./delete-vpcs.py [vpc-id] [region] \n \
        ie. ./delete-vpcs.py vpc-000000 us-west-2')

# Set Arguments
vpc_id = sys.argv[1]
region = sys.argv[2]

# Get All IGWS
igws = json.loads(subprocess.check_output("aws --region=" + region + " --filters=Name=attachment.vpc-id,Values=" + vpc_id + " ec2 describe-internet-gateways", shell=True), \
    object_hook=lambda d: SimpleNamespace(**d))

# Loop Through IGWS and delete / detatch
for ig in igws.InternetGateways:
    ig = ig.InternetGatewayId
    subprocess.check_output("aws --region=" + region + " ec2 detach-internet-gateway --internet-gateway-id=" + str(ig) + " --vpc-id=" + vpc_id, shell=True)
    subprocess.check_output("aws --region=" + region +  " ec2 delete-internet-gateway --internet-gateway-id=" + str(ig), shell=True)

# Get All Subnets
subs = json.loads(subprocess.check_output("aws --region=" + region + " ec2 describe-subnets", shell=True), \
    object_hook=lambda d: SimpleNamespace(**d))

# Loop Through Subnets and delete
for sub in subs.Subnets:
    sub = sub.SubnetId
    subprocess.check_output("aws --region=" + region + " ec2 delete-subnet --subnet-id=" + str(sub), shell=True)

try:
    # Delete vpc
    subprocess.check_output("aws --region=" + region + " ec2 delete-vpc --vpc-id=" + vpc_id, shell=True)
except subprocess.CalledProcessError as e:
    pass