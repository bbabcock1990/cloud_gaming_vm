import logging
import os
import json
import azure.functions as func
from azure.identity import DefaultAzureCredential
from azure.mgmt.resource import ResourceManagementClient
from azure.mgmt.compute import ComputeManagementClient
# NetworkManagementClient is imported but not used in the provided logic,
# it can be removed if not needed for other potential enhancements.
# from azure.mgmt.network import NetworkManagementClient 
from dotenv import load_dotenv

# Load environment variables from .env file for local development
load_dotenv()

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request to GetDeployments.')

    try:
        # Get subscription ID from environment variable
        subscription_id = os.environ.get("AZURE_SUBSCRIPTION_ID")
        if not subscription_id:
            logging.error("Azure Subscription ID not found in environment variables.")
            return func.HttpResponse(
                 "Azure Subscription ID not configured.",
                 status_code=500
            )

        # Authenticate using DefaultAzureCredential
        # For local development, ensure you've logged in via Azure CLI or have AZURE_TENANT_ID, AZURE_CLIENT_ID, and AZURE_CLIENT_SECRET set
        credential = DefaultAzureCredential()

        # Initialize management clients
        resource_client = ResourceManagementClient(credential, subscription_id)
        compute_client = ComputeManagementClient(credential, subscription_id)
        # network_client = NetworkManagementClient(credential, subscription_id) # Not used yet

        deployments_info = []

        # List all resource groups
        resource_groups = resource_client.resource_groups.list()

        for rg in resource_groups:
            if rg.tags and rg.tags.get('managedBy') == 'GameSessionDashboard':
                deployment_name_tag = rg.tags.get('deploymentName')
                if not deployment_name_tag:
                    logging.warning(f"Resource group {rg.name} is managedBy GameSessionDashboard but missing deploymentName tag. Skipping.")
                    continue

                vm_name = f"{deployment_name_tag}-vm"
                public_ip_from_deployment = None
                deployment_status = "Unknown"

                # Get the latest successful deployment to fetch outputs
                try:
                    # Sort deployments by timestamp to get the latest one, if multiple exist.
                    # This example takes the first successful one found.
                    group_deployments = resource_client.deployments.list_by_resource_group(rg.name)
                    for dep in sorted(group_deployments, key=lambda d: d.properties.timestamp, reverse=True):
                        if dep.properties.provisioning_state == 'Succeeded':
                            deployment_status = dep.properties.provisioning_state
                            if dep.properties.outputs and 'vmPublicIP' in dep.properties.outputs and 'value' in dep.properties.outputs['vmPublicIP']:
                                public_ip_from_deployment = dep.properties.outputs['vmPublicIP']['value']
                            break # Found the latest successful deployment
                    else: # No successful deployment found
                        logging.warning(f"No successful deployment found in resource group {rg.name} to fetch outputs.")
                        deployment_status = "NoSuccessfulDeployment"


                except Exception as e:
                    logging.error(f"Error fetching deployments for resource group {rg.name}: {str(e)}")
                    # Continue to try and get VM info even if deployment output fails
                
                vm_power_state = "Unknown"
                try:
                    vm = compute_client.virtual_machines.get(rg.name, vm_name, expand='instanceView')
                    if vm.instance_view and vm.instance_view.statuses:
                        for status in vm.instance_view.statuses:
                            if status.code and status.code.startswith('PowerState/'):
                                vm_power_state = status.code.split('/')[-1]
                                break
                except Exception as e:
                    logging.error(f"Error fetching VM details for {vm_name} in {rg.name}: {str(e)}")
                    # If VM details cannot be fetched, we might not want to include this deployment
                    # or report it with unknown VM state. For now, we'll add it with "Unknown" state.

                deployments_info.append({
                    "namePrefix": deployment_name_tag,
                    "resourceGroupName": rg.name,
                    "deploymentStatus": deployment_status,
                    "vmPowerState": vm_power_state,
                    "publicIP": public_ip_from_deployment, # Primarily from deployment output
                    "region": rg.location
                })

        if not deployments_info:
            return func.HttpResponse(
                json.dumps([]), # Return empty list if no matching deployments found
                status_code=200,
                mimetype="application/json"
            )

        return func.HttpResponse(
            json.dumps(deployments_info),
            status_code=200,
            mimetype="application/json"
        )

    except Exception as e:
        logging.error(f"An unexpected error occurred: {str(e)}")
        return func.HttpResponse(
             "An unexpected error occurred. Please check the logs for more details.",
             status_code=500
        )
