import boto3
import os
import sys
import time

aws_region = os.getenv("AWS_REGION")
aws_account_id = os.getenv("AWS_ACCOUNT_ID")
appsync_api_id = os.environ.get("APPSYNC_API_ID")
appsync_merged_api_id = os.environ.get("APPSYNC_MERGED_API_ID")
appsync_client = boto3.client("appsync", region_name=aws_region)


def schema_merge_appsync_apis():
    try:
        response = appsync_client.list_source_api_associations(
            apiId=appsync_api_id
        )
        if response["sourceApiAssociationSummaries"]:
            association_id = response["sourceApiAssociationSummaries"][0]["associationId"]
            appsync_client.start_schema_merge(
                associationId=association_id,
                mergedApiIdentifier=appsync_merged_api_id,
            )
            print(f"[terraform] schema merged {association_id} with {appsync_merged_api_id}")
        else:
            print("[terraform] No association found to schema merge.")
    except Exception as e:
        print(f"[terraform] failed to schema merge {association_id}: {e}")
        sys.exit(1)


def main():
    schema_merge_appsync_apis()


main()
