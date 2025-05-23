import logging
import os
import json
import azure.functions as func
from azure.identity import DefaultAzureCredential
from azure.mgmt.resource import ResourceManagementClient
from dotenv import load_dotenv

# Load environment variables from .env file for local development
load_dotenv()

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request to DeleteDeployment.')

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
        credential = DefaultAzureCredential()
        resource_client = ResourceManagementClient(credential, subscription_id)

        # Get namePrefix from request (query parameter or body)
        name_prefix = req.params.get('namePrefix')
        if not name_prefix:
            try:
                req_body = req.get_json()
                name_prefix = req_body.get('namePrefix')
            except ValueError:
                pass # No JSON body or namePrefix in body

        if not name_prefix:
            logging.error("namePrefix not found in request query parameters or body.")
            return func.HttpResponse(
                 "Please pass a namePrefix on the query string or in the request body",
                 status_code=400
            )

        resource_group_name = f"{name_prefix}-rg"
        logging.info(f"Attempting to delete resource group: {resource_group_name}")

        try:
            # Check if resource group exists before attempting deletion
            if resource_client.resource_groups.check_existence(resource_group_name):
                logging.info(f"Resource group {resource_group_name} found. Starting deletion.")
                # Start the resource group deletion
                delete_poller = resource_client.resource_groups.begin_delete(resource_group_name)
                
                # For now, we return 202 Accepted as it's a long-running operation.
                # Customer might want to add logic to check delete_poller.status() or wait_for_completion.
                return func.HttpResponse(
                    json.dumps({"message": f"Resource group {resource_group_name} deletion started."}),
                    status_code=202,
                    mimetype="application/json"
                )
            else:
                logging.warning(f"Resource group {resource_group_name} not found. No action taken.")
                return func.HttpResponse(
                    json.dumps({"message": f"Resource group {resource_group_name} not found."}),
                    status_code=404, # Not Found
                    mimetype="application/json"
                )

        except Exception as e: # Catch exceptions during the deletion process specifically
            logging.error(f"Error during deletion of resource group {resource_group_name}: {str(e)}")
            return func.HttpResponse(
                 f"Error deleting resource group {resource_group_name}. Check logs.",
                 status_code=500
            )

    except Exception as e: # Catch broader exceptions (e.g., during auth, setup)
        logging.error(f"An unexpected error occurred: {str(e)}")
        return func.HttpResponse(
             "An unexpected error occurred. Please check the logs for more details.",
             status_code=500
        )
