import subprocess
import sys

def install(packages):
    for name in packages:
        subprocess.call([sys.executable, '-m', 'pip', 'install', name])

packages_to_install = ['azure-identity', 'azure-mgmt-network']
install(packages_to_install)

from azure.identity import DefaultAzureCredential
from azure.mgmt.network import NetworkManagementClient

private_link_ids = sys.argv[1:]
subscription_ids = []
for private_link_id in private_link_ids:
    subscription_ids.append(private_link_id.split("/")[2])

def approve_private_endpoints(subscription_ids, private_link_ids):
    for sub_id in subscription_ids:
        try:
            credential = DefaultAzureCredential()
            network_client = NetworkManagementClient(credential, sub_id)
        except:
            raise ValueError("Credentials error")
    
        private_endpoints = []
        for private_links in network_client.private_link_services.list_by_subscription():
            if private_links.id in private_link_ids:
                for private_endpoint_connection in private_links.private_endpoint_connections:
                    if private_endpoint_connection.private_link_service_connection_state.status  !=  "Approved":
                        private_endpoint_connection.private_link_service_connection_state.status = "Approved"
                    try:
                        network_client.private_link_services.update_private_endpoint_connection(private_endpoint_connection.id.split("/")[4], private_endpoint_connection.id.split("/")[8], private_endpoint_connection.name, private_endpoint_connection )
                    except:
                        raise ValueError("Update error")

approve_private_endpoints(subscription_ids, private_link_ids)

