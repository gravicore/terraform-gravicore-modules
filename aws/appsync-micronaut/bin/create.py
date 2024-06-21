import boto3
import os
import sys

ERROR_ASSOCIATION_EXISTS = "SourceApiAssociation already exists"

aws_region = os.getenv("AWS_REGION")
aws_account_id = os.getenv("AWS_ACCOUNT_ID")
appsync_api_id = os.environ.get("APPSYNC_API_ID")
appsync_merged_api_id = os.environ.get("APPSYNC_MERGED_API_ID")
appsync_client = boto3.client("appsync", region_name=aws_region)


def associate_appsync_apis():
    try:
        appsync_client.associate_merged_graphql_api(
            mergedApiIdentifier=appsync_merged_api_id,
            sourceApiIdentifier=appsync_api_id
        )
        print(f"[terraform] associated {appsync_api_id} with {appsync_merged_api_id}")
    except Exception as e:
        print(f"[terraform] failed to associate {appsync_api_id} with {appsync_merged_api_id}: {e}")
        if ERROR_ASSOCIATION_EXISTS in str(e):
            print("[terraform] association already exists, ignoring")
        else:
            sys.exit(1)


def main():
    associate_appsync_apis()


main()
