import logging
import os
import json
import azure.functions as func
from azure.identity import DefaultAzureCredential
from azure.mgmt.resource import ResourceManagementClient
from azure.core.exceptions import ResourceNotFoundError

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('DeleteDeployment HTTP trigger function processed a request.')

    name_prefix = req.params.get('namePrefix')
    if not name_prefix:
        try:
            req_body = req.get_json()
            name_prefix = req_body.get('namePrefix')
        except ValueError:
            pass # No JSON body or namePrefix in body

    if not name_prefix:
        logging.error("namePrefix parameter not found in query string or request body.")
        return func.HttpResponse("Please pass namePrefix in the query string or request body", status_code=400)

    subscription_id = os.environ.get("AZURE_SUBSCRIPTION_ID")
    if not subscription_id:
        logging.error("AZURE_SUBSCRIPTION_ID environment variable not set.")
        return func.HttpResponse("Server configuration error: Subscription ID not set.", status_code=500)

    resource_group_name = f"{name_prefix}-rg"

    try:
        credential = DefaultAzureCredential()
        resource_client = ResourceManagementClient(credential, subscription_id)

        logging.info(f"Attempting to delete resource group: {resource_group_name}")

        # Check if resource group exists before attempting delete
        try:
            resource_client.resource_groups.get(resource_group_name)
            logging.info(f"Resource group {resource_group_name} found. Proceeding with deletion.")
        except ResourceNotFoundError:
            logging.warning(f"Resource group {resource_group_name} not found. Nothing to delete.")
            return func.HttpResponse(
                json.dumps({'message': f"Resource group {resource_group_name} not found. Nothing to delete."}),
                mimetype="application/json",
                status_code=404
            )
        
        poller = resource_client.resource_groups.begin_delete(resource_group_name)
        
        # For HTTP functions, return 202 Accepted as deletion is long-running.
        return func.HttpResponse(
            json.dumps({'message': f"Deletion of resource group {resource_group_name} started."}),
            mimetype="application/json",
            status_code=202
        )

    except Exception as e:
        logging.error(f"Error during resource group deletion for {resource_group_name}: {str(e)}")
        return func.HttpResponse(f"Deletion failed for {resource_group_name}: {str(e)}", status_code=500)
