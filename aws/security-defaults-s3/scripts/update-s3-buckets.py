#!/usr/bin/env python
import subprocess
import json
import time
import sys, os, shutil
from types import SimpleNamespace

# CLI Arguments
if len(sys.argv) != 6:
    raise ValueError('Usage: ./update-s3-buckets.py [s3-bucket-name] [versioning] [access_logging] [ssl_request_only] [access_log_s3_bucket] \n \
        ie. ./update-s3-buckets.py my-bucket true true true module-name-s3-logs')
#
# Set Arguments
bucket_name = sys.argv[1]
versioning = sys.argv[2]
access_logging = sys.argv[3]
ssl_request_only = sys.argv[4]
access_log_s3_bucket = sys.argv[5]

# Set Versioning
try:
    versioning_status = "Status=Disabled"
    if(versioning == "true"):
        versioning_status = "Status=Enabled"
    subprocess.check_output("aws s3api put-bucket-versioning --bucket " + str(bucket_name) + " --versioning-configuration " + versioning_status, shell=True)
except subprocess.CalledProcessError as e:
    sys.exit(1)

# Set Access Logs
try:
    if(access_logging == "true"):

        # Check if Bucket Access Logging is enabled
        is_bucket_logging = False
        bucket_logging = subprocess.check_output("aws s3api get-bucket-logging --bucket " + str(bucket_name), shell=True)

        # If not empty list
        if bucket_logging is not b'':
            bucket_logging = json.loads(bucket_logging, object_hook=lambda d: SimpleNamespace(**d))
            if(hasattr(bucket_logging, "LoggingEnabled")):
                is_bucket_logging = True

        if not is_bucket_logging: 
            f = open(bucket_name + "_logging.json", "w")
            f.write('{' + \
                '"LoggingEnabled": {' + \
                '    "TargetBucket": "' + access_log_s3_bucket + '",' + \
                '    "TargetPrefix": "' + bucket_name + '/access_logs/"' + \
                '}' + \
            '}')
            f.close()
            subprocess.check_output("aws s3api put-bucket-logging --bucket " + bucket_name + " --bucket-logging-status file://" + bucket_name + "_logging.json", shell=True)
    else:
        f = open(bucket_name + "_logging.json", "w")
        f.write("""{}""")
        f.close()
        subprocess.check_output("aws s3api put-bucket-logging --bucket " + bucket_name + " --bucket-logging-status file://" + bucket_name + "_logging.json", shell=True)

except subprocess.CalledProcessError as e:
    sys.exit(1)

# Set SSL Requests Only
try:
    if(ssl_request_only == "true"):

        subprocess_success = True
        try: 
            bucket_policy = subprocess.check_output("aws s3api get-bucket-policy --bucket " + bucket_name + " --query Policy --output text", shell=True, stderr=subprocess.DEVNULL)
            bucket_policy = json.loads(bucket_policy, object_hook=lambda d: SimpleNamespace(**d))
        except subprocess.CalledProcessError as e:
            subprocess_success = False

        has_ssl_only_policy = False
        if(subprocess_success):
            if(hasattr(bucket_policy, 'Statement')):
                for statement in bucket_policy.Statement:
                    if(hasattr(statement, "Action") and hasattr(statement, "Condition")):
                        if(statement.Action == 's3:*' and hasattr(statement.Condition, "Bool")):
                            if(hasattr(statement.Condition.Bool, 'aws:SecureTransport')):
                                if(vars(statement.Condition.Bool)['aws:SecureTransport'] == "false"):
                                    has_ssl_only_policy = True
                                    break
        
        if (has_ssl_only_policy == False):
            allow_ssl_only_policy = '{' + \
                '"Sid": "AllowSSLRequestsOnly",' + \
                '"Action": "s3:*",' + \
                '"Effect": "Deny",' + \
                '"Resource": [' + \
                '    "arn:aws:s3:::' + bucket_name + '",' + \
                '    "arn:aws:s3:::' + bucket_name + '/*"' + \
                '],' + \
                '"Condition": {' + \
                '    "Bool": {' + \
                '    "aws:SecureTransport": "false"' + \
                '    }' + \
                '},' + \
                '"Principal": "*"' + \
                '}'

            if(subprocess_success and hasattr(bucket_policy, "Statement")):
                json_ssl_allow_policy = json.loads(allow_ssl_only_policy, object_hook=lambda d: SimpleNamespace(**d))
                bucket_policy.Statement.append(json_ssl_allow_policy)
                statement_policy = json.dumps(bucket_policy, default=lambda o: o.__dict__, sort_keys=True, indent=4)
                final_policy = json.loads(str(statement_policy), object_hook=lambda d: SimpleNamespace(**d))
            else:
                final_policy = json.loads('{ "Statement" : [' + str(allow_ssl_only_policy) + '] }', object_hook=lambda d: SimpleNamespace(**d))

            f = open(bucket_name + "_ssl_policy.json", "w")
            f.write(json.dumps(final_policy, default=lambda o: o.__dict__, sort_keys=True, indent=4))
            f.close()

            subprocess.check_output("aws s3api put-bucket-policy --bucket " + bucket_name + " --policy file://" + bucket_name + "_ssl_policy.json", shell=True)
    else:

        subprocess_success = True
        try: 
            bucket_policy = subprocess.check_output("aws s3api get-bucket-policy --bucket " + bucket_name + " --query Policy --output text", shell=True, stderr=subprocess.DEVNULL)
            bucket_policy = json.loads(bucket_policy, object_hook=lambda d: SimpleNamespace(**d))
        except subprocess.CalledProcessError as e:
            subprocess_success = False

        has_ssl_only_policy = False
        statements = []
        if(subprocess_success):
            if(hasattr(bucket_policy, 'Statement')):
                for statement in bucket_policy.Statement:
                    is_ssl_only_policy = False
                    if(hasattr(statement, "Action") and hasattr(statement, "Condition")):
                        if(statement.Action == 's3:*' and hasattr(statement.Condition, "Bool")):
                            if(hasattr(statement.Condition.Bool, 'aws:SecureTransport')):
                                if(vars(statement.Condition.Bool)['aws:SecureTransport'] == "false"):
                                    has_ssl_only_policy = True
                                    is_ssl_only_policy = True
                    if not is_ssl_only_policy:
                        statements.append(statement)
                    

        if(has_ssl_only_policy):

            final_statements = '{ "Statement": "" }'
            if (len(statements) > 0):
                final_statements = '{ "Statement" : ' + json.dumps(statements, default=lambda o: o.__dict__, sort_keys=True, indent=4) + ' }'

                f = open(bucket_name + "_ssl_policy.json", "w")
                f.write(final_statements)
                f.close()

                subprocess.check_output("aws s3api put-bucket-policy --bucket " + bucket_name + " --policy file://" + bucket_name + "_ssl_policy.json", shell=True)
            else:
                subprocess.check_output("aws s3api delete-bucket-policy --bucket " + bucket_name, shell=True)

        
except subprocess.CalledProcessError as e:
    sys.exit(1)