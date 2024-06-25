import boto3
import os

MAX_RESULTS = 5

appsync_api_name = os.getenv("APPSYNC_API_NAME")
aws_region = os.getenv("AWS_REGION")
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


def main():
    api_id = get_appsync_api_id_by_name(appsync_api_name)

    if api_id:
        try:
            appsync_client.delete_graphql_api(apiId=api_id)
            print(f"[terraform] appsync api '{appsync_api_name}' with id '{api_id}' has been deleted")
        except Exception as e:
            print(f"[terraform] failed to delete appsync api '{appsync_api_name}': {e}")
    else:
        print(f"[terraform] api named '{appsync_api_name}' not found")


main()
