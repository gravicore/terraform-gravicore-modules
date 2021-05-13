#!/usr/bin/env python
import subprocess
import json
import time
import sys, os, shutil
from types import SimpleNamespace

# CLI Arguments
if len(sys.argv) != 4:
    raise ValueError('Usage: ./update-functions.py [lambda-function-name] [subnet-ids] [security-group-ids] \n \
        ie. ./update-functions.py my-function subnet-12345,subnet-12346 sg-12345,sg-12346 ')
#
# Set Arguments
function_name = sys.argv[1]
subnet_ids = sys.argv[2]
security_group_ids = sys.argv[3]

iam_role = ""

# Get Lambda Role
try:
    lambda_config = json.loads(subprocess.check_output("aws lambda get-function-configuration --function-name " + str(function_name), shell=True), \
    object_hook=lambda d: SimpleNamespace(**d))
    iam_role = lambda_config.Role
    iam_role = iam_role.split('/')[1]

except subprocess.CalledProcessError as e:
    sys.exit(1)

execute_policy_exists = False
execute_policy_already_exists = False
check_policy_counter = 0

# Attempt to attach policies
while (execute_policy_exists == False and check_policy_counter < 10):
    if iam_role == "" :
        print('IAM Role Not Found')
        sys.exit(1)

    # Get Attached Policies
    try:
        attached_policies = json.loads(subprocess.check_output("aws iam list-attached-role-policies --role-name " + str(iam_role), shell=True), \
            object_hook=lambda d: SimpleNamespace(**d))
        for policy in attached_policies.AttachedPolicies:
            if (str(policy.PolicyName) == 'AWSLambdaVPCAccessExecutionRole'):
                execute_policy_exists = True

                if check_policy_counter == 0 :
                    execute_policy_already_exists = True
                break

    except subprocess.CalledProcessError as e:
        sys.exit(1)

    # If execute policy isn't attached
    if execute_policy_exists == False:
        try:
            # Attach Policy to Role
            subprocess.check_output("aws iam attach-role-policy --role-name " + str(iam_role) + \
                " --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole", shell=True)
            check_policy_counter = 10
        except subprocess.CalledProcessError as e:
            pass

    else:
        check_policy_counter = 10

    check_policy_counter = check_policy_counter + 1
    time.sleep(10)

# Try Adding Default VPC
try:
    # Add VPC to Lambda
    subprocess.check_output("aws lambda update-function-configuration --function-name " + str(function_name) + \
        " --vpc-config SubnetIds=" + subnet_ids + ",SecurityGroupIds=" + security_group_ids, shell=True)
except subprocess.CalledProcessError as e:
    pass

# Detach execute policy
if execute_policy_already_exists == False :
    try:
        # Dettach Policy to Role
        subprocess.check_output("aws iam detach-role-policy --role-name " + str(iam_role) + \
            " --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole", shell=True)
    except subprocess.CalledProcessError as e:
        sys.exit(1)