# Azure Game Session Dashboard - Deployment Guide

This guide provides steps to deploy the Azure Game Session Dashboard application, which consists of a Python Azure Function App backend and a vanilla JavaScript frontend hosted on Azure Static Web Apps.

## I. Prerequisites

Before you begin, ensure you have the following:

*   **Azure Subscription:** You'll need an active Azure subscription.
*   **Azure CLI:** Installed and configured. Login with `az login`.
*   **GitHub Account:** To fork and manage the repository.
*   **Fork of the Repository:** Fork this repository to your GitHub account. All deployment steps will assume you are working from your fork.

## II. Backend Azure Function App Deployment

The backend logic resides in the `BackendFunctions_Python` directory.

*   **Recommended Method:** Using Azure CLI or the Azure Tools extension in VS Code.

**Steps:**

1.  **Create Azure Function App Resource:**
    *   Open Azure Portal or use Azure CLI.
    *   Create a new "Function App" resource.
    *   **Configuration:**
        *   **Publish:** Code
        *   **Runtime stack:** Python (choose a version supported by Azure Functions, e.g., 3.9, 3.10, 3.11)
        *   **Operating System:** Linux (recommended)
        *   **Hosting Plan:** Consumption (Serverless) or an App Service Plan. Consumption is cost-effective for event-driven workloads.
        *   Choose a region.
        *   A new Azure Storage account will typically be created or you can link an existing one.

2.  **Configure Application Settings:**
    Navigate to your Function App in the Azure Portal -> Configuration -> Application settings. Add the following:
    *   `AZURE_SUBSCRIPTION_ID`: Your Azure Subscription ID.
    *   `AZURE_TENANT_ID`: Your Azure Tenant ID (can be found in Azure Active Directory properties).
    *   `GITHUB_REPOSITORY`: Your GitHub username and repository name (e.g., `your_username/your_forked_repo_name`). This is used by the `CreateDeployment` function to construct the raw URL to your `main.bicep` file.
    *   `AzureWebJobsStorage`: Connection string to an Azure Storage account. This is usually auto-filled if a new storage account was created with the Function App.
    *   `FUNCTIONS_WORKER_RUNTIME`: `python` (should be auto-set based on your runtime choice).

3.  **Enable System-Assigned Managed Identity:**
    *   In your Function App -> Settings -> Identity.
    *   Under "System assigned", switch Status to **On** and Save.
    *   Note the Object (principal) ID once created.

4.  **Grant RBAC Roles to the Managed Identity:**
    The Managed Identity needs permissions to manage resources in your subscription.
    *   Navigate to your **Subscription** in the Azure Portal.
    *   Go to **Access control (IAM)**.
    *   Click **Add** -> **Add role assignment**.
    *   **Roles:**
        *   Assign the **Reader** role: This allows the Function App to list resource groups and deployments.
        *   Assign the **Contributor** role: This allows the Function App to create and delete resource groups and deployments (including VMs, networks, etc.).
            *   **Security Note:** The `Contributor` role is broad. For a production environment, it's highly recommended to create a custom RBAC role with only the specific permissions required (e.g., `Microsoft.Resources/deployments/*`, `Microsoft.Resources/subscriptions/resourcegroups/*`, `Microsoft.Compute/virtualMachines/read`, `Microsoft.Compute/virtualMachines/instanceView/action`, `Microsoft.Network/publicIPAddresses/read`).
    *   **Assign access to:** Managed identity.
    *   **Select members:** Choose the System-Assigned Managed Identity of your Function App.
    *   Review and assign.

5.  **Deploy Function Code:**
    Deploy the code from the `BackendFunctions_Python` directory.
    *   Navigate to the `BackendFunctions_Python` directory in your local terminal.
    *   Ensure `requirements.txt` is up-to-date.
    *   One common method is using the Azure Functions Core Tools:
        ```bash
        # Install if you haven't already: npm install -g azure-functions-core-tools@4 --unsafe-perm true
        func azure functionapp publish <YourFunctionAppName>
        ```
        You might be prompted to build native dependencies if applicable. Using `--zip` or other flags might be needed based on your setup.
    *   Alternatively, use the Azure Tools extension in VS Code for deployment.

6.  **Note on `local.settings.json`:**
    The `local.settings.json` file in `BackendFunctions_Python` is for local development. Values like `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET` are used for local debugging with a Service Principal. When deployed to Azure, the Function App uses its System-Assigned Managed Identity for authentication with Azure services, so these specific credential settings are not used or needed in the Azure environment's Application Settings.

7.  **CORS (Cross-Origin Resource Sharing):**
    If you are deploying the Function App separately and *not* linking it as a managed backend to the Static Web App (see SWA deployment section), you'll need to configure CORS:
    *   In your Function App -> Settings -> CORS.
    *   Add the URL of your Static Web App (e.g., `https://your-swa-name.azurestaticapps.net`) to the allowed origins. You can also use `*` for development, but be more specific for production.

## III. Frontend Azure Static Web App Deployment

The frontend code resides in the `Frontend` directory.

*   **Method:** Using Azure Portal or Azure CLI.

**Steps:**

1.  **Create Static Web App Resource:**
    *   In the Azure Portal, search for "Static Web Apps" and click Create.
    *   Select your subscription and resource group.
    *   Enter a name for your SWA.
    *   Choose a region.
    *   **Deployment details:**
        *   Source: GitHub.
        *   Sign in to GitHub and authorize Azure.
        *   Select your Organization, forked Repository, and Branch (e.g., `main` or `master`).
    *   **Build Details:**
        *   **Build Presets:** Custom
        *   **App location:** `/Frontend`
        *   **Api location:** Leave this blank. We are deploying our Azure Function App separately for more control.
        *   **Output location:** Leave this blank (or as default, e.g., `dist` or `www`). Since our frontend is plain HTML, JS, and CSS, there's no explicit "build output" folder other than `Frontend` itself. SWA will serve files from the `App location`.
    *   Review and create. The initial creation will trigger a GitHub Action to deploy your SWA.

2.  **Authentication:**
    *   Azure Static Web Apps have built-in authentication with Azure Active Directory (AAD), GitHub, etc.
    *   After deployment, you can navigate to your Static Web App resource in Azure Portal -> Configuration.
    *   Under the "Authentication" section, you can see the identity providers. AAD is typically enabled by default. The frontend `app.js` uses the `/.auth/login/aad` and `/.auth/logout` routes.

3.  **API Backend Configuration:**
    Since the Function App is deployed separately, you need to link it to your Static Web App:
    *   Navigate to your Static Web App resource in the Azure Portal.
    *   Go to **APIs** (under Settings).
    *   Click **Link**.
    *   Select your deployed Azure Function App from the "Backend resource type" and then your Function App name.
    *   Click Link.
    *   This configuration makes your Function App accessible under the `/api` route of your Static Web App (e.g., `https://your-swa-name.azurestaticapps.net/api/GetDeployments`). The `apiBaseUrl = '/api'` in `Frontend/app.js` relies on this.

4.  **Review `Frontend/staticwebapp.config.json`:**
    *   The `staticwebapp.config.json` file in the `Frontend` directory provides configuration for navigation fallback, API routing, and headers.
    *   Since the Function App is deployed and linked separately, the `platform` section in `staticwebapp.config.json` (specifically `apiRuntime` and `apiBuildCommand`) is not directly used by SWA for building or managing the API. It's more for documentation or if you were to switch to SWA "managed functions" by placing the API code inside the SWA project structure (e.g., in an `api` folder).

## IV. Testing and Verification

After deploying all components, thoroughly test the application:

**A. Authentication and Authorization:**
   1.  Navigate to the Static Web App URL. You should be prompted to log in or see a login button.
   2.  Log in using valid Azure AD credentials. Verify successful login and display of your username/email.
   3.  Log out. Verify you are redirected or the UI updates to a logged-out state.
   4.  Attempt to access dashboard features or API endpoints directly without logging in (if possible, e.g., by trying to call an API from browser dev tools). Verify access is denied or data is not shown.

**B. Dashboard Functionality (`GetDeployments`):**
   1.  **No Deployments:** If this is a fresh setup, the dashboard should display a message like "No active game sessions found."
   2.  **With Deployments:** After creating one or more sessions:
       *   Verify all active game sessions are listed.
       *   For each session, check that the displayed information is accurate: Name Prefix, Resource Group Name, Region, Deployment Status, VM Power State, and Public IP.
       *   Confirm the "Delete" button is visible for each session.

**C. Create Game Session (`CreateDeployment`):**
   1.  Click the "Create New Game Session" button.
   2.  **Valid Inputs:** Fill in all required fields (`namePrefix`, `region`, `vmPassword`) with valid data. Submit the form.
       *   Verify a "Deployment started" message appears.
       *   After a few minutes (Azure deployment time), the new session should appear on the dashboard.
       *   Verify in the Azure portal that the corresponding Resource Group and resources were created.
   3.  **Missing Required Inputs:** Try to submit the form with one or more required fields empty (e.g., no `namePrefix`). Verify user-friendly error messages are displayed on the frontend and the deployment is not attempted.
   4.  **Client IP Detection:** Ensure your client IP is correctly detected and used (this is passed to the Bicep template for NSG rules). You might need to check the NSG rules in Azure for the deployed VM.

**D. Delete Game Session (`DeleteDeployment`):**
   1.  From the dashboard, click the "Delete" button for an existing game session.
   2.  Verify a confirmation prompt appears.
   3.  Confirm deletion. Verify a "Deletion started" message appears.
   4.  After some time, the session should disappear from the dashboard.
   5.  Verify in the Azure portal that the corresponding Resource Group and its resources have been deleted.
   6.  Attempt to delete a session again immediately after starting deletion. Observe behavior (it should ideally indicate it's already in progress or fail gracefully).

**E. Error Handling and UI Robustness:**
   1.  If possible during testing (and safe to do so), try to simulate backend errors (e.g., by temporarily stopping the Azure Function App or revoking its permissions) and observe if the frontend displays user-friendly error messages.
   2.  Check for any console errors in the browser's developer tools during normal operation.
   3.  (Optional) Briefly check if the UI is reasonably usable on different screen sizes (basic responsiveness).

**F. Bicep Template Link Verification:**
   1.  Ensure the `CreateDeployment` function is correctly resolving the path to `main.bicep` (via the `GITHUB_REPOSITORY` environment variable). If deployments fail with template errors, this link is a primary suspect. The `DEPLOYMENT_GUIDE.MD` mentions this in "Important Notes" - re-emphasize checking the Function App logs for any errors related to fetching the template.

## V. Important Notes

*   **Bicep `template_link` in `CreateDeployment` Function:**
    The `CreateDeployment` function in `BackendFunctions_Python/CreateDeployment/__init__.py` constructs a URL to your `main.bicep` file using the `GITHUB_REPOSITORY` environment variable (e.g., `https://raw.githubusercontent.com/{GITHUB_REPOSITORY}/main/main.bicep`). Ensure this environment variable is set correctly in your Function App's application settings and that the `main` branch (or your default branch) contains the `main.bicep` file at the root. If you encounter issues where the template cannot be found, you might need to adjust this logic or temporarily hardcode the direct raw URL to your `main.bicep` in your forked repository for testing.
*   **Costs:**
    *   Azure Static Web Apps has a free tier suitable for this project.
    *   Azure Functions Consumption plan also has a generous free grant.
    *   **The primary cost will be associated with the Azure Virtual Machines and related resources (disks, public IPs) created by the Bicep template.** The template uses Spot VMs by default to reduce costs, but Spot VMs can be evicted. Be mindful of the VM sizes and number of deployments you create. Delete resource groups when not in use to avoid ongoing charges.
*   **Client IP for Bicep:**
    The `CreateDeployment` frontend logic attempts to fetch the client's public IP using `https://api.ipify.org`. This IP is then passed to the `CreateDeployment` Azure Function, which in turn passes it to the `main.bicep` template. This is typically used for firewall rules (e.g., in an NSG). Ensure this is the desired behavior.

This completes the deployment guide.The `Frontend/staticwebapp.config.json` file and the `DEPLOYMENT_GUIDE.md` have been created successfully.

*   `Frontend/staticwebapp.config.json` contains the necessary configurations for navigation fallback, API routing, authentication (placeholder for roles), networking, global headers, and platform settings (with a note about managed functions vs. separate deployment).
*   `DEPLOYMENT_GUIDE.md` provides a comprehensive step-by-step guide for prerequisites, deploying the backend Azure Function App (including RBAC for Managed Identity), deploying the frontend Azure Static Web App, linking the backend, post-deployment checks, and important considerations like the Bicep template link and costs.

Both files are ready as per the requirements of the subtask.
