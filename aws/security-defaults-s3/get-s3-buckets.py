#!/usr/bin/env python
import subprocess
import json
import sys, os, shutil
from types import SimpleNamespace

# CLI Arguments
if len(sys.argv) != 2:
    raise ValueError('Usage: ./get-s3-buckets.py [aws-profile] \n \
        ie. ./get-s3-buckets.py default')

# Set Arguments
aws_profile = sys.argv[1]

# Get All S3 Associated to AWS Profile
s3buckets = json.loads(subprocess.check_output("aws s3api list-buckets --profile " + aws_profile, shell=True), \
    object_hook=lambda d: SimpleNamespace(**d))

# Debug
print ("Getting S3 Buckets")

# Loop Through Buckets
for bucket in s3buckets.Buckets:

    # Check if Bucket Access Logging is enabled
    is_bucket_logging = "logging:false"
    bucket_logging = subprocess.check_output("aws s3api get-bucket-logging --bucket " + str(bucket.Name) + " --profile " + aws_profile, shell=True)

    # If not empty list
    if bucket_logging is not b'':
        bucket_logging = json.loads(bucket_logging, object_hook=lambda d: SimpleNamespace(**d))
        if(hasattr(bucket_logging, "LoggingEnabled")):
            is_bucket_logging = "logging:true"

    # Check if Bucket Versioning is enabled
    is_bucket_versioning = "versioning:false"
    bucket_versioning = subprocess.check_output("aws s3api get-bucket-versioning --bucket " + str(bucket.Name) + " --profile " + aws_profile, shell=True)

    # If not empty list
    if bucket_versioning is not b'':
        bucket_versioning = json.loads(bucket_versioning, object_hook=lambda d: SimpleNamespace(**d))
        if(hasattr(bucket_versioning, "Status")):
            if(bucket_versioning.Status == "Enabled"):
                is_bucket_versioning = "versioning:true"
    
    # Check if Bucket ssl_request_only is enabled
    is_bucket_ssl = "ssl_only:false"
    
    subprocess_success = True
    try:
        bucket_ssl_only = subprocess.check_output("aws s3api get-bucket-policy --bucket " + str(bucket.Name) + " --profile " + aws_profile, stderr=subprocess.DEVNULL)
    except subprocess.CalledProcessError as e:
        subprocess_success = False

    # If not empty list
    if subprocess_success:
        bucket_ssl_only = json.loads(bucket_ssl_only, object_hook=lambda d: SimpleNamespace(**d))

        # Check if ssl_request_only
        if(hasattr(bucket_ssl_only, "Policy")):
            bucket_ssl_policy = json.loads(bucket_ssl_only.Policy, object_hook=lambda d: SimpleNamespace(**d))
            if(hasattr(bucket_ssl_policy, "Statement")):
                for statement in bucket_ssl_policy.Statement:
                    if(hasattr(statement, "Action") and hasattr(statement, "Condition")):
                        if(statement.Action == 's3:*' and hasattr(statement.Condition, "Bool")):
                            if(hasattr(statement.Condition.Bool, 'aws:SecureTransport')):
                                if(vars(statement.Condition.Bool)['aws:SecureTransport'] == "false"):
                                    is_bucket_ssl = "ssl_only:true"
                                    break

    print ('"' + str(bucket.Name) + '",' + is_bucket_versioning + ',' + is_bucket_logging + "," + is_bucket_ssl)