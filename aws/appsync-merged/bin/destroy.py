import boto3
import os

aws_region = os.getenv("AWS_REGION")
appsync_client = boto3.client("appsync", region_name=aws_region)


def delete_appsync_api_by_name(api_name):
    try:
        response = appsync_client.list_graphql_apis()
    except Exception as e:
        print(f"[terraform] failed to list appsync apis: {e}")
        return

    api_id = None
    for api in response["graphqlApis"]:
        if api["name"] == api_name:
            api_id = api["apiId"]
            break

    if not api_id:
        print(f"[terraform] api named '{api_name}' not found")
        return

    try:
        appsync_client.delete_graphql_api(apiId=api_id)
        print(f"[terraform] appsync api '{api_name}' with id '{api_id}' has been deleted")
    except Exception as e:
        print(f"[terraform] failed to delete appsync api '{api_name}': {e}")


def main():
    api_name = os.getenv("APPSYNC_API_NAME")
    delete_appsync_api_by_name(api_name)


main()
