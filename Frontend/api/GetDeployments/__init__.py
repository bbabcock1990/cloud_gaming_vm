import logging
import os
import json
import azure.functions as func
from azure.identity import DefaultAzureCredential
from azure.mgmt.resource import ResourceManagementClient
from azure.mgmt.compute import ComputeManagementClient
# from azure.mgmt.network import NetworkManagementClient # Not strictly needed if IP from output

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('GetDeployments HTTP trigger function processed a request.')

    try:
        credential = DefaultAzureCredential()
        subscription_id = os.environ.get("AZURE_SUBSCRIPTION_ID")
        if not subscription_id:
            logging.error("AZURE_SUBSCRIPTION_ID environment variable not set.")
            return func.HttpResponse("Server configuration error: Subscription ID not set.", status_code=500)

        resource_client = ResourceManagementClient(credential, subscription_id)
        compute_client = ComputeManagementClient(credential, subscription_id)
        # network_client = NetworkManagementClient(credential, subscription_id) # If needed for fallback IP

        deployments_details = []
        resource_groups = resource_client.resource_groups.list(filter="tagName eq 'managedBy' and tagValue eq 'GameSessionDashboard'")

        for rg in resource_groups:
            deployment_name = rg.tags.get('deploymentName')
            if not deployment_name:
                logging.warning(f"Resource group {rg.name} is tagged 'managedBy:GameSessionDashboard' but missing 'deploymentName' tag.")
                continue

            vm_name = f"{deployment_name}-vm"
            public_ip_value = "Not Found"
            vm_power_state = "Not Found"
            deployment_status = "Not Found"
            
            try:
                # Get deployment status and outputs
                # Assuming one main deployment per RG, find the most recent successful one if multiple exist
                rg_deployments = resource_client.deployments.list_by_resource_group(rg.name)
                latest_deployment = None
                for dep in rg_deployments:
                    if dep.properties.provisioning_state == 'Succeeded': # or other relevant states
                        if latest_deployment is None or dep.properties.timestamp > latest_deployment.properties.timestamp:
                            latest_deployment = dep
                
                if latest_deployment:
                    deployment_status = latest_deployment.properties.provisioning_state
                    if latest_deployment.properties.outputs and 'vmPublicIP' in latest_deployment.properties.outputs:
                        public_ip_value = latest_deployment.properties.outputs['vmPublicIP']['value']
                else:
                    logging.info(f"No successful deployment found in RG {rg.name} to fetch outputs.")

            except Exception as e:
                logging.error(f"Error fetching deployment details for RG {rg.name}: {str(e)}")


            try:
                vm = compute_client.virtual_machines.get(rg.name, vm_name, expand='instanceView')
                if vm.instance_view and vm.instance_view.statuses:
                    for status in vm.instance_view.statuses:
                        if status.code and status.code.startswith('PowerState/'):
                            vm_power_state = status.display_status
                            break
            except Exception as e:
                logging.error(f"Error fetching VM details for {vm_name} in RG {rg.name}: {str(e)}")


            deployments_details.append({
                'namePrefix': deployment_name,
                'resourceGroupName': rg.name,
                'region': rg.location,
                'deploymentStatus': deployment_status,
                'vmPowerState': vm_power_state,
                'publicIP': public_ip_value
            })

        return func.HttpResponse(
            json.dumps(deployments_details),
            mimetype="application/json"
        )

    except Exception as e:
        logging.error(f"Error in GetDeployments function: {str(e)}")
        return func.HttpResponse("Failed to retrieve deployments.", status_code=500)
