import boto3
import os
import json

MAX_RESULTS = 5

appsync_api_name = os.getenv("APPSYNC_API_NAME")
aws_region = os.getenv("AWS_REGION")
cognito_user_pool_id = os.getenv("COGNITO_USER_POOL_ID")
execution_role_arn = os.getenv("EXECUTION_ROLE_ARN")
module_path = os.getenv("MODULE_PATH")
appsync_client = boto3.client("appsync", region_name=aws_region)


def get_appsync_api_id_by_name(appsync_api_name):
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
            if api["name"] == appsync_api_name:
                return api["apiId"]
        next_token = response.get("nextToken")
        if not next_token:
            break
    return None


def create_appsync_api(appsync_api_name, user_pool_id):
    response = appsync_client.create_graphql_api(
        name=appsync_api_name,
        authenticationType="AMAZON_COGNITO_USER_POOLS",
        apiType="MERGED",
        userPoolConfig={
            "userPoolId": user_pool_id,
            "awsRegion": aws_region,
            "defaultAction": "ALLOW",
        },
        mergedApiExecutionRoleArn=execution_role_arn,
        xrayEnabled=True,
        enhancedMetricsConfig={
            "resolverLevelMetricsBehavior": "PER_RESOLVER_METRICS",
            "dataSourceLevelMetricsBehavior": "PER_DATA_SOURCE_METRICS",
            "operationLevelMetricsConfig": "ENABLED",
        },
        logConfig={
            "fieldLogLevel": "NONE",
            "cloudWatchLogsRoleArn": execution_role_arn,
            "excludeVerboseContent": True,
        },
    )
    return response["graphqlApi"]["apiId"]


def main():
    api_id = get_appsync_api_id_by_name(appsync_api_name)

    if api_id:
        print(f"[terraform] graphql api '{appsync_api_name}' already exists: {api_id}")
    else:
        api_id = create_appsync_api(appsync_api_name, cognito_user_pool_id)
        print(f"[terraform] created graphql api '{appsync_api_name}' with id: {api_id}")

    with open(f"{module_path}/output.json", "w") as file:
        json.dump({"api_id": api_id}, file)


main()
