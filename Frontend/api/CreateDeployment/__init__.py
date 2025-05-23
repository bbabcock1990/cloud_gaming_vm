import logging
import os
import json
import azure.functions as func
from azure.identity import DefaultAzureCredential
from azure.mgmt.resource import ResourceManagementClient
import time # For unique deployment names

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('CreateDeployment HTTP trigger function processed a request.')

    try:
        req_body = req.get_json()
    except ValueError:
        logging.error("Invalid JSON format in request body.")
        return func.HttpResponse("Please pass a valid JSON object in the request body", status_code=400)

    name_prefix = req_body.get('namePrefix')
    region = req_body.get('region')
    vm_password = req_body.get('vmPassword')
    client_ip = req_body.get('clientIP')

    if not all([name_prefix, region, vm_password, client_ip]):
        logging.error("Missing required parameters in request body.")
        return func.HttpResponse("Missing required parameters: namePrefix, region, vmPassword, clientIP", status_code=400)

    vm_size = req_body.get('vmSize', 'Standard_NV32as_v4') # Default VM size
    install_steam = req_body.get('installSteam', True)
    install_sunshine = req_body.get('installSunshine', True)
    
    subscription_id = os.environ.get("AZURE_SUBSCRIPTION_ID")
    if not subscription_id:
        logging.error("AZURE_SUBSCRIPTION_ID environment variable not set.")
        return func.HttpResponse("Server configuration error: Subscription ID not set.", status_code=500)

    try:
        credential = DefaultAzureCredential()
        resource_client = ResourceManagementClient(credential, subscription_id)

        # Construct Bicep template URI
        # This might need adjustment based on how SWA exposes repository files or if GITHUB_REPOSITORY is available
        github_repo = os.environ.get('GITHUB_REPOSITORY')
        if github_repo:
            # Assumes main.bicep is at the root of the repository
            template_uri = f"https://raw.githubusercontent.com/{github_repo}/main/main.bicep"
        else:
            # Fallback or error if GITHUB_REPOSITORY is not set.
            # For SWA managed functions, relative paths from the function to the bicep file might be an option if the repo is checked out.
            # e.g., template_uri = os.path.join(os.path.dirname(req.route_params.get('function_dir', '.')), '../../main.bicep') # This is speculative
            # For now, rely on GITHUB_REPOSITORY or a fixed placeholder that user must configure in App Settings if var is not present
            logging.warning("GITHUB_REPOSITORY environment variable not found. Attempting to use a placeholder template URI from MAIN_BICEP_TEMPLATE_URI.")
            # IMPORTANT: User might need to set this as an SWA Application Setting if GITHUB_REPOSITORY isn't auto-populated.
            template_uri_placeholder = os.environ.get("MAIN_BICEP_TEMPLATE_URI", "YOUR_RAW_GITHUB_MAIN_BICEP_URI") # Default to a clear placeholder
            if "YOUR_RAW_GITHUB_MAIN_BICEP_URI" in template_uri_placeholder:
                 logging.error("Bicep template URI is a placeholder. Please configure MAIN_BICEP_TEMPLATE_URI app setting if GITHUB_REPOSITORY is not available.")
                 return func.HttpResponse("Server configuration error: Bicep template URI not configured.", status_code=500)
            template_uri = template_uri_placeholder
        
        logging.info(f"Using Bicep template URI: {template_uri}")

        parameters = {
            'namePrefix': {'value': name_prefix},
            'region': {'value': region},
            'vmSize': {'value': vm_size},
            'vmPassword': {'value': vm_password},
            'clientIP': {'value': client_ip},
            'installSteam': {'value': install_steam},
            'installSunshine': {'value': install_sunshine}
        }

        deployment_properties = {
            'mode': 'Incremental',
            'templateLink': {
                'uri': template_uri
            },
            'parameters': parameters
        }
        
        deployment_name = f"deployment-{name_prefix}-{int(time.time())}"

        logging.info(f"Starting Bicep deployment: {deployment_name}")
        
        # Subscription-level deployment
        poller = resource_client.deployments.begin_create_or_update_at_subscription_scope(
            deployment_name,
            {'properties': deployment_properties}
        )
        
        # For HTTP functions, it's best to return 202 Accepted as deployment is long-running
        # client.wait() would likely timeout.
        
        return func.HttpResponse(
            json.dumps({'message': 'Deployment started.', 'deploymentName': deployment_name}),
            mimetype="application/json",
            status_code=202
        )

    except Exception as e:
        logging.error(f"Error during deployment: {str(e)}")
        # Consider if the error message should be more generic to the client for security
        return func.HttpResponse(f"Deployment failed: {str(e)}", status_code=500)
