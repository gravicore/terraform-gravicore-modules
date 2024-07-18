import boto3
import os
import sys
import time

aws_region = os.getenv("AWS_REGION")
aws_account_id = os.getenv("AWS_ACCOUNT_ID")
appsync_api_id = os.environ.get("APPSYNC_API_ID")
appsync_client = boto3.client("appsync", region_name=aws_region)


def disassociate_appsync_apis():
    try:
        response = appsync_client.list_source_api_associations(
            apiId=appsync_api_id
        )
        if response["sourceApiAssociationSummaries"]:
            association_id = response["sourceApiAssociationSummaries"][0]["associationId"]
            response = appsync_client.disassociate_merged_graphql_api(
                associationId=association_id,
                sourceApiIdentifier=appsync_api_id
            )
            print(f"[terraform] disassociated {appsync_api_id} with {association_id}")

            # giving AWS some time to get us the right results
            # when destroying the AppSync GraphQL API
            time.sleep(5)
        else:
            print("[terraform] No association found to disassociate.")
    except Exception as e:
        print(f"[terraform] failed to disassociate {appsync_api_id}: {e}")
        sys.exit(1)


def main():
    disassociate_appsync_apis()


main()
