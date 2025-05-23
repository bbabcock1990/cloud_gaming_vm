import logging
import os
import json
import time # For generating unique deployment names
import azure.functions as func
from azure.identity import DefaultAzureCredential
from azure.mgmt.resource import ResourceManagementClient
from dotenv import load_dotenv

# Load environment variables from .env file for local development
load_dotenv()

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request to CreateDeployment.')

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

        # Request Body Processing
        try:
            req_body = req.get_json()
        except ValueError:
            logging.error("Invalid JSON format in request body.")
            return func.HttpResponse(
                 "Please pass a valid JSON object in the request body",
                 status_code=400
            )

        name_prefix = req_body.get('namePrefix')
        region = req_body.get('region')
        vm_password = req_body.get('vmPassword')
        client_ip = req_body.get('clientIP')

        # Validate required parameters
        if not all([name_prefix, region, vm_password, client_ip]):
            missing_params = [param for param, value in {
                "namePrefix": name_prefix, "region": region, 
                "vmPassword": vm_password, "clientIP": client_ip
            }.items() if not value]
            logging.error(f"Missing required parameters: {', '.join(missing_params)}")
            return func.HttpResponse(
                f"Missing required parameters: {', '.join(missing_params)}",
                status_code=400
            )

        # Optional parameters with defaults
        vm_size = req_body.get('vmSize', 'Standard_NV32as_v4')
        install_steam = req_body.get('installSteam', True)
        install_sunshine = req_body.get('installSunshine', True)
        
        # Deployment Logic
        parameters = {
            'namePrefix': {'value': name_prefix},
            'region': {'value': region},
            'vmSize': {'value': vm_size},
            'vmPassword': {'value': vm_password},
            'clientIP': {'value': client_ip},
            'installSteam': {'value': install_steam},
            'installSunshine': {'value': install_sunshine}
        }

        # IMPORTANT: This URI needs to be the raw path to main.bicep in your GitHub repo
        # Using GITHUB_REPOSITORY for GitHub Actions, otherwise a placeholder.
        github_repo = os.environ.get('GITHUB_REPOSITORY', 'YOUR_USER/YOUR_REPO') # Placeholder if not in GitHub Actions
        template_link = f"https://raw.githubusercontent.com/{github_repo}/main/main.bicep"
        
        # Log the template link being used, especially for debugging in different environments
        logging.info(f"Using Bicep template link: {template_link}")


        deployment_properties = {
            'mode': 'Incremental',
            'templateLink': {
                'uri': template_link
            },
            'parameters': parameters
        }

        # Generate a unique deployment name
        deployment_name = f"deployment-{name_prefix}-{int(time.time())}"

        logging.info(f"Starting subscription-level deployment: {deployment_name}")
        
        # Start the subscription-level deployment
        deployment_poller = resource_client.deployments.begin_create_or_update_at_subscription_scope(
            deployment_name, 
            {'properties': deployment_properties}
        )
        
        # For now, we return 202 Accepted as it's a long-running operation.
        # Customer might want to add logic to check deployment_poller.status() or wait_for_completion.
        
        return func.HttpResponse(
             json.dumps({"message": "Deployment started.", "deploymentName": deployment_name, "templateLinkUsed": template_link}),
             status_code=202,
             mimetype="application/json"
        )

    except Exception as e:
        logging.error(f"An unexpected error occurred: {str(e)}")
        return func.HttpResponse(
             "An unexpected error occurred. Please check the logs for more details.",
             status_code=500
        )
