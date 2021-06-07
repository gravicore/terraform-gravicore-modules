#!/usr/bin/env python
import subprocess
import json
import time
import sys, os, shutil
from types import SimpleNamespace

# CLI Arguments
if len(sys.argv) != 3:
    raise ValueError('Usage: ./update-ec2-instances.py [instances-id] [enable_http_tokens] \n \
        ie. ./update-ec2-instances instance-12345 true')
#
# Set Arguments
instance_id = sys.argv[1]
enable_http_tokens = sys.argv[2]

# Enable HttpTokens for MetaDataOptions
try:
    http_tokens_setting = "optional"
    if(enable_http_tokens == "true"):
        http_tokens_setting = "required"
        
    subprocess.check_output("aws ec2 modify-instance-metadata-options --instance-id " + str(instance_id) + " --http-tokens " + http_tokens_setting, shell=True)
except subprocess.CalledProcessError as e:
    sys.exit(1)