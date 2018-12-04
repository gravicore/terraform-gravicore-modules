# 1) Assume role for running cloud formation
CREDENTIALS=`aws sts assume-role --role-arn ${ROLE_ARN} --role-session-name RoleSession --duration-seconds 900 --output=json`

# 2) Capture current credentials to reset after executing command
export ORIGINAL_AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
export ORIGINAL_AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}

# 3) Set AWS Assumed Role Credentials on ENV
export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=`echo ${CREDENTIALS} | jq -r '.Credentials.AccessKeyId'`
export AWS_SECRET_ACCESS_KEY=`echo ${CREDENTIALS} | jq -r '.Credentials.SecretAccessKey'`
export AWS_SESSION_TOKEN=`echo ${CREDENTIALS} | jq -r '.Credentials.SessionToken'`
export AWS_EXPIRATION=`echo ${CREDENTIALS} | jq -r '.Credentials.Expiration'`

# 4) Execute command as assumed role
aws s3 ls

# 5) Clean up assume role environment variables
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN
unset AWS_EXPIRATION

# 6) Reset to original credentials
export AWS_ACCESS_KEY_ID=${ORIGINAL_AWS_ACCESS_KEY_ID}
export AWS_SECRET_ACCESS_KEY=${ORIGINAL_AWS_SECRET_ACCESS_KEY}

# 7) Clean up temporary storage
unset ORIGINAL_AWS_ACCESS_KEY_ID
unset ORIGINAL_AWS_SECRET_ACCESS_KEY