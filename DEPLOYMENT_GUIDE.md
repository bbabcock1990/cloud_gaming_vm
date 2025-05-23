# Azure Game Session Dashboard - Deployment Guide (Managed Functions)

This guide provides steps to deploy the Azure Game Session Dashboard application. This version uses Azure Static Web Apps with **managed Azure Functions**, simplifying the deployment process.

## I. Prerequisites

Before you begin, ensure you have the following:

*   **Azure Subscription:** You'll need an active Azure subscription.
*   **Azure CLI:** Installed and configured. Login with `az login`.
*   **GitHub Account:** To fork and manage the repository.
*   **Fork of the Repository:** Fork this repository to your GitHub account. All deployment steps will assume you are working from your fork.

## II. Deploying the Azure Static Web App (with Managed Functions)

The Azure Static Web App (SWA) will host both the frontend (from the `/Frontend` directory) and the Python API functions (from the `/Frontend/api` directory).

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
        *   **App location:** `/Frontend` (This is where your HTML, CSS, JS files are)
        *   **Api location:** `api` (This tells SWA to look for Azure Functions code in the `/Frontend/api` directory relative to the `app_location`, or simply `api` if the build context correctly infers it from the root of `app_location`. The standard convention is to specify `api` if your functions are in `Frontend/api` and `app_location` is `Frontend`)
        *   **Output location:** Typically blank. SWA will serve static content from `app_location` and build the API from `api_location`.
    *   Review and create. The initial creation will trigger a GitHub Action to build and deploy your SWA and the managed functions.

2.  **Configure Application Settings:**
    These settings are configured in your Static Web App's "Configuration" section in the Azure portal.
    *   `AZURE_SUBSCRIPTION_ID`: Your Azure Subscription ID.
    *   `AZURE_TENANT_ID`: Your Azure Tenant ID (can be found in Azure Active Directory properties; used by `DefaultAzureCredential` in your functions).
    *   `MAIN_BICEP_TEMPLATE_URI`: (Optional, but recommended as a fallback) The raw GitHub URL to your `main.bicep` file (e.g., `https://raw.githubusercontent.com/YOUR_USER/YOUR_REPO/main/main.bicep`). The `CreateDeployment` function attempts to use the `GITHUB_REPOSITORY` environment variable (often available in SWA build/runtime) first, but this provides a manual override if needed.

3.  **Grant Permissions to Static Web App's Managed Identity:**
    The Static Web App has a system-assigned managed identity that needs permissions to manage Azure resources (create/delete deployments and resource groups).
    *   After the SWA is created, navigate to it in the Azure Portal.
    *   Go to **Identity** (under Settings).
    *   Ensure the "System assigned" status is **On**. Note the Object (principal) ID.
    *   Navigate to your **Subscription** in the Azure Portal.
    *   Go to **Access control (IAM)**.
    *   Click **Add** -> **Add role assignment**.
    *   **Roles:**
        *   Assign the **Reader** role: This allows the Function App to list resource groups and deployments.
        *   Assign the **Contributor** role: This allows the Function App to create and delete resource groups and deployments.
            *   **Security Note:** The `Contributor` role is broad. For a production environment, it's highly recommended to create a custom RBAC role with only the specific permissions required by the functions (e.g., related to deployments, resource groups, VM status, etc.).
    *   **Assign access to:** Managed identity.
    *   **Select members:** Search for and select the System-Assigned Managed Identity of your Static Web App.
    *   Review and assign.

4.  **Authentication:**
    *   Azure Static Web Apps have built-in authentication with Azure Active Directory (AAD), GitHub, etc.
    *   Navigate to your Static Web App resource in Azure Portal -> Configuration.
    *   Under the "Authentication" section, you can see the identity providers. AAD is typically enabled by default. The frontend `app.js` uses the `/.auth/login/aad` and `/.auth/logout` routes.

## III. Testing and Verification

After deploying all components, thoroughly test the application:

**A. Authentication and Authorization:**
   1.  Navigate to the Static Web App URL. You should be prompted to log in or see a login button.
   2.  Log in using valid Azure AD credentials. Verify successful login and display of your username/email.
   3.  Log out. Verify you are redirected or the UI updates to a logged-out state.
   4.  Attempt to access API endpoints directly (e.g., `/api/GetDeployments`) without logging in. SWA's built-in auth may still allow this if the function's `authLevel` is `anonymous`. The frontend UI should restrict actions if not logged in.

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
   3.  **Missing Required Inputs:** Try to submit the form with one or more required fields empty. Verify user-friendly error messages are displayed on the frontend and the deployment is not attempted.
   4.  **Client IP Detection:** Ensure your client IP is correctly detected by the frontend and passed to the API.

**D. Delete Game Session (`DeleteDeployment`):**
   1.  From the dashboard, click the "Delete" button for an existing game session.
   2.  Verify a confirmation prompt appears.
   3.  Confirm deletion. Verify a "Deletion started" message appears.
   4.  After some time, the session should disappear from the dashboard.
   5.  Verify in the Azure portal that the corresponding Resource Group and its resources have been deleted.

**E. Error Handling and UI Robustness:**
   1.  If possible, simulate backend errors (e.g., by providing invalid parameters that the Bicep template would reject) and observe if the frontend displays user-friendly error messages.
   2.  Check for any console errors in the browser's developer tools during normal operation.
   3.  Check the SWA's "Functions" -> "Log stream" or "Application Insights" (if configured for the functions) for any API errors.

**F. Bicep Template Link Verification:**
   1.  The `CreateDeployment` function uses the `GITHUB_REPOSITORY` environment variable (usually available in SWA) or the `MAIN_BICEP_TEMPLATE_URI` app setting to find `main.bicep`. If deployments fail with template errors, check:
       *   The SWA Application Settings for `MAIN_BICEP_TEMPLATE_URI` (if you set it).
       *   The Function App logs (via SWA) for messages about which URI is being used.
       *   Ensure the `main.bicep` file is at the root of your repository in the specified branch.

## IV. Important Notes

*   **Bicep `template_link` in `CreateDeployment` Function:**
    As mentioned in testing, the `CreateDeployment` function relies on either the `GITHUB_REPOSITORY` environment variable (automatically provided by SWA build/runtime typically) or the `MAIN_BICEP_TEMPLATE_URI` application setting you configure in the SWA. If `GITHUB_REPOSITORY` is not available or incorrect in the function's runtime environment, you *must* set `MAIN_BICEP_TEMPLATE_URI` in the SWA's configuration for deployments to work.
*   **Costs:**
    *   Azure Static Web Apps has a free tier suitable for this project for hosting the frontend and managed functions (within limits).
    *   **The primary cost will be associated with the Azure Virtual Machines and related resources (disks, public IPs) created by the Bicep template.** The template uses Spot VMs by default to reduce costs, but Spot VMs can be evicted. Be mindful of the VM sizes and number of deployments you create. Delete resource groups when not in use to avoid ongoing charges.
*   **Client IP for Bicep:**
    The `CreateDeployment` frontend logic attempts to fetch the client's public IP using `https://api.ipify.org`. This IP is then passed to the API and subsequently to the `main.bicep` template, typically for NSG rules.

This completes the deployment guide for the Azure Static Web App with managed functions.The `DEPLOYMENT_GUIDE.MD` file was created in the previous turn with content reflecting the simplified Azure Static Web Apps with managed functions architecture.

**Verification of Changes:**

*   **Section II (Backend Deployment):** This section was entirely omitted, as planned.
*   **Section III (Frontend SWA Deployment) Renamed to "II. Deploying the Azure Static Web App (with Managed Functions)":** This was done.
*   **Build Settings for SWA:**
    *   **App location:** Set to `/Frontend`.
    *   **Api location:** Set to `api`. This correctly tells SWA to look for functions in `/Frontend/api` (relative to `app_location`, or as SWA interprets it, from the root of the `app_location` if `api` is within it).
    *   Mention of linking a separate Function App was removed.
*   **Application Settings for SWA:**
    *   A new subsection "Configure Application Settings" was added under the SWA deployment section.
    *   It lists `AZURE_SUBSCRIPTION_ID`, `AZURE_TENANT_ID`, and `MAIN_BICEP_TEMPLATE_URI` (with explanation about `GITHUB_REPOSITORY` fallback).
*   **RBAC/Permissions for SWA's Managed Identity:**
    *   A new subsection "Grant Permissions to Static Web App's Managed Identity" was added.
    *   It correctly explains that the SWA's system-assigned managed identity needs `Reader` and `Contributor` (or custom) roles.
*   **CORS Configuration:** Mention of CORS was removed.
*   **Section "IV. Testing and Verification" (Now "III."):**
    *   Renumbered correctly.
    *   Test cases were reviewed and are appropriate for the new architecture.
    *   Emphasis on checking SWA deployment logs and the function's environment variables (`GITHUB_REPOSITORY`, `MAIN_BICEP_TEMPLATE_URI`) was included in "F. Bicep Template Link Verification."
*   **Section "V. Important Notes" (Now "IV."):**
    *   Renumbered correctly.
    *   The note on "Bicep `template_link`" was updated to reflect the SWA environment variables/app settings.

The guide now accurately reflects the simplified deployment process. No further modifications are needed based on the prompt.
