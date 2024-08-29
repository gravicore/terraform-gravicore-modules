import boto3
import os
import json
import sys

ERROR_ASSOCIATION_EXISTS = "SourceApiAssociation already exists"
MAX_RESULTS = 5

api_name = os.getenv("APPSYNC_API_NAME")
aws_region = os.getenv("AWS_REGION")
cognito_user_pool_id = os.getenv("COGNITO_USER_POOL_ID")
execution_role_arn = os.getenv("EXECUTION_ROLE_ARN")
source_ids = json.loads(os.getenv("APPSYNC_API_IDS"))
appsync_client = boto3.client("appsync", region_name=aws_region)


def get_appsync_api_id_by_name(api_name):
    next_token = None
    while True:
        command = {
            "apiType": "MERGED",
            "maxResults": MAX_RESULTS,
        }
        if next_token is not None:
            command["nextToken"] = next_token

        response = appsync_client.list_graphql_apis(**command)
        for api in response["graphqlApis"]:
            if api["name"] == api_name:
                return api["apiId"]
        next_token = response.get("nextToken")
        if not next_token:
            break
    return None


def create_appsync_api(api_name, user_pool_id):
    response = appsync_client.create_graphql_api(
        name=api_name,
        authenticationType="AMAZON_COGNITO_USER_POOLS",
        apiType="MERGED",
        userPoolConfig={
            "userPoolId": user_pool_id,
            "awsRegion": aws_region,
            "defaultAction": "ALLOW",
        },
        mergedApiExecutionRoleArn=execution_role_arn,
    )
    return response["graphqlApi"]["apiId"]


def associate_appsync_source_apis(merged_id):
    for source_id in source_ids:
        try:
            appsync_client.associate_merged_graphql_api(
                mergedApiIdentifier=merged_id,
                sourceApiIdentifier=source_id
            )
            print(f"[terraform] associated {source_id} with {merged_id}")
        except Exception as e:
            print(f"[terraform] failed to associate {source_id} with {merged_id}: {e}")
            if ERROR_ASSOCIATION_EXISTS in str(e):
                print("[terraform] association already exists, ignoring")
            else:
                sys.exit(1)


def main():
    api_id = get_appsync_api_id_by_name(api_name)
    if api_id:
        print(f"[terraform] graphql api '{api_name}' already exists: {api_id}")
    else:
        api_id = create_appsync_api(api_name, cognito_user_pool_id)
        print(f"[terraform] created graphql api '{api_name}' with id: {api_id}")

    associate_appsync_source_apis(api_id)
    with open("output.json", "w") as file:
        json.dump({"api_id": api_id}, file)


main()
