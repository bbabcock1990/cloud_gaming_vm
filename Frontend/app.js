// Global Variables
const apiBaseUrl = '/api'; // Standard for SWA linked backends

// DOM Elements
const authStatusDiv = document.getElementById('authStatus');
const showCreateModalBtn = document.getElementById('showCreateModalBtn');
const createModal = document.getElementById('createModal');
const createDeploymentForm = document.getElementById('createDeploymentForm'); // Ensure this form doesn't submit traditionally
const createDeploymentBtn = document.getElementById('createDeploymentBtn');
const deploymentsListDiv = document.getElementById('deploymentsList');
const messageAreaDiv = document.getElementById('messageArea');

// Form Inputs (inside createModal)
const namePrefixInput = document.getElementById('namePrefix');
const regionInput = document.getElementById('region');
const vmPasswordInput = document.getElementById('vmPassword');
const vmSizeInput = document.getElementById('vmSize');
const installSteamInput = document.getElementById('installSteam');
const installSunshineInput = document.getElementById('installSunshine');
const modalCloseButton = createModal.querySelector('.close-button');

// Event Listeners
if (showCreateModalBtn) {
    showCreateModalBtn.addEventListener('click', () => {
        if (createModal) createModal.style.display = 'block';
        clearMessage();
    });
}

if (modalCloseButton) {
    modalCloseButton.addEventListener('click', () => {
        if (createModal) createModal.style.display = 'none';
    });
}

window.addEventListener('click', (event) => {
    if (event.target === createModal) {
        createModal.style.display = 'none';
    }
});

// Ensure the button click calls createDeployment, not form submission
if (createDeploymentBtn) {
    createDeploymentBtn.addEventListener('click', (event) => {
        event.preventDefault(); // Prevent default form submission if it's a submit button
        createDeployment();
    });
}
// If the button is not type="submit" in a form, preventDefault might not be strictly needed
// but it's good practice if it's inside a <form> tag.
// Alternatively, ensure the button is type="button". The HTML has it as type="button" already.

// --- Authentication and Data Fetching ---

async function checkAuthStatus() {
    console.log("Checking authentication status...");
    if (authStatusDiv) authStatusDiv.innerHTML = 'Checking login status...';
    if (showCreateModalBtn) showCreateModalBtn.disabled = true;

    try {
        const response = await fetch('/.auth/me');
        const payload = await response.json();
        const { clientPrincipal } = payload;

        if (clientPrincipal) {
            console.log("User is logged in:", clientPrincipal);
            if (authStatusDiv) {
                authStatusDiv.innerHTML = `Welcome, ${clientPrincipal.userDetails}! <a href="/.auth/logout">Logout</a>`;
            }
            if (showCreateModalBtn) showCreateModalBtn.disabled = false;
            getDeployments();
        } else {
            console.log("User is not logged in.");
            if (authStatusDiv) {
                authStatusDiv.innerHTML = '<a href="/.auth/login/aad">Login with Microsoft Account</a>';
            }
            if (deploymentsListDiv) deploymentsListDiv.innerHTML = 'Please login to view deployments.';
            if (showCreateModalBtn) showCreateModalBtn.disabled = true;
        }
    } catch (error) {
        console.error('Error checking auth status:', error);
        if (authStatusDiv) authStatusDiv.textContent = 'Error checking auth status. See console for details.';
        showMessage('Error checking auth status: ' + error.message, true);
    }
}

async function getDeployments() {
    console.log("Fetching deployments...");
    if (deploymentsListDiv) deploymentsListDiv.innerHTML = 'Loading deployments...';
    clearMessage();

    try {
        const response = await fetch(`${apiBaseUrl}/GetDeployments`, {
            headers: { 'Content-Type': 'application/json' }
        });

        if (!response.ok) {
            const errorText = await response.text();
            throw new Error(`Error fetching deployments: ${response.status} ${response.statusText}. Details: ${errorText}`);
        }
        
        const deployments = await response.json();
        console.log("Deployments received:", deployments);
        renderDeployments(deployments);

    } catch (error) {
        console.error('Error in getDeployments:', error);
        showMessage('Failed to load deployments: ' + error.message, true);
        if (deploymentsListDiv) deploymentsListDiv.innerHTML = 'Failed to load deployments. Please try again.';
    }
}

function renderDeployments(deployments) {
    if (!deploymentsListDiv) return;
    deploymentsListDiv.innerHTML = ''; 

    if (!deployments || deployments.length === 0) {
        deploymentsListDiv.innerHTML = 'No active game session deployments found.';
        return;
    }

    deployments.forEach(dep => {
        const card = document.createElement('div');
        card.className = 'deployment-card';
        card.innerHTML = `
            <h3>${dep.namePrefix}</h3>
            <p><strong>Resource Group:</strong> ${dep.resourceGroupName}</p>
            <p><strong>Region:</strong> ${dep.region}</p>
            <p><strong>Status:</strong> ${dep.deploymentStatus || 'N/A'}</p> 
            <p><strong>VM Power State:</strong> ${dep.vmPowerState || 'N/A'}</p>
            <p><strong>Public IP:</strong> ${dep.publicIP || 'N/A'}</p>
            <button class="deleteBtn" data-nameprefix="${dep.namePrefix}">Delete</button>
        `;
        deploymentsListDiv.appendChild(card);

        const deleteButton = card.querySelector('.deleteBtn');
        if (deleteButton) {
            deleteButton.addEventListener('click', () => {
                deleteDeployment(dep.namePrefix);
            });
        }
    });
    console.log("Deployments rendered.");
}

// --- Create and Delete Functions ---

async function createDeployment() {
    console.log("Attempting to create deployment...");
    clearMessage();

    // Validate inputs
    if (!namePrefixInput.value || !regionInput.value || !vmPasswordInput.value) {
        showMessage('Name Prefix, Region, and VM Password are required.', true);
        return;
    }

    // Disable button to prevent multiple submissions
    if (createDeploymentBtn) createDeploymentBtn.disabled = true;
    showMessage('Starting deployment... Fetching client IP...', false);

    let clientPublicIP = '';
    try {
        const ipResponse = await fetch('https://api.ipify.org?format=json');
        if (!ipResponse.ok) {
            throw new Error(`Failed to fetch client IP: ${ipResponse.statusText}`);
        }
        const ipData = await ipResponse.json();
        clientPublicIP = ipData.ip;
        showMessage('Client IP fetched. Proceeding with deployment...', false);
    } catch (error) {
        console.error('Error fetching client IP:', error);
        showMessage('Error fetching client IP: ' + error.message + '. Deployment aborted.', true);
        if (createDeploymentBtn) createDeploymentBtn.disabled = false; // Re-enable button
        return;
    }

    const deploymentData = {
        namePrefix: namePrefixInput.value,
        region: regionInput.value,
        vmPassword: vmPasswordInput.value,
        clientIP: clientPublicIP,
        vmSize: vmSizeInput.value || 'Standard_NV32as_v4', // Default if empty
        installSteam: installSteamInput.checked,
        installSunshine: installSunshineInput.checked
    };

    console.log("Sending deployment data:", deploymentData);

    try {
        const response = await fetch(`${apiBaseUrl}/CreateDeployment`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(deploymentData)
        });

        const resultText = await response.text(); // Get text first for better error details
        let resultJson;
        try {
            resultJson = JSON.parse(resultText);
        } catch (e) {
            // If parsing fails, use the text as the message if response not OK
            if (!response.ok) {
                 throw new Error(resultText || `Error creating deployment: ${response.statusText}`);
            }
            resultJson = { message: "Deployment initiated, but response was not valid JSON."}; // Or handle as appropriate
        }


        if (!response.ok) { // Check status like 200, 201, 202
            throw new Error(resultJson.message || `Error creating deployment: ${response.statusText}`);
        }

        showMessage(`Deployment "${resultJson.deploymentName || deploymentData.namePrefix}" started successfully.`, false);
        if (createModal) createModal.style.display = 'none';
        createDeploymentForm.reset(); // Reset form fields
        
        // Refresh deployments list after a short delay
        setTimeout(getDeployments, 3000); 

    } catch (error) {
        console.error('Error in createDeployment:', error);
        showMessage('Error starting deployment: ' + error.message, true);
    } finally {
        if (createDeploymentBtn) createDeploymentBtn.disabled = false; // Re-enable button
    }
}

async function deleteDeployment(namePrefix) {
    console.log(`Attempting to delete deployment: ${namePrefix}`);
    if (!confirm(`Are you sure you want to delete the deployment "${namePrefix}"? This will delete the entire resource group.`)) {
        return;
    }
    
    clearMessage();
    showMessage(`Starting deletion of ${namePrefix}...`, false);

    try {
        const response = await fetch(`${apiBaseUrl}/DeleteDeployment?namePrefix=${encodeURIComponent(namePrefix)}`, {
            method: 'DELETE'
        });

        const resultText = await response.text(); // Get text first
        let resultJson;
        try {
            resultJson = JSON.parse(resultText);
        } catch (e) {
            if (!response.ok) {
                throw new Error(resultText || `Error deleting deployment: ${response.statusText}`);
            }
            resultJson = { message: "Deletion initiated, but response was not valid JSON."};
        }

        if (!response.ok) { // Check status like 200, 202
            throw new Error(resultJson.message || `Error deleting deployment: ${response.statusText}`);
        }

        showMessage(resultJson.message || `Deletion of "${namePrefix}" started successfully.`, false);
        
        // Refresh deployments list after a short delay
        setTimeout(getDeployments, 3000);

    } catch (error) {
        console.error('Error in deleteDeployment:', error);
        showMessage(`Error deleting ${namePrefix}: ` + error.message, true);
    }
}

// --- Utility Functions ---

function showMessage(message, isError = false) {
    if (messageAreaDiv) {
        messageAreaDiv.textContent = message;
        messageAreaDiv.className = isError ? 'error-message' : 'success-message';
    }
    console.log(`Message: ${message}, IsError: ${isError}`);
}

function clearMessage() {
    if (messageAreaDiv) {
        messageAreaDiv.textContent = '';
        messageAreaDiv.className = '';
    }
}

// --- Initial Load ---
document.addEventListener('DOMContentLoaded', () => {
    console.log("DOM fully loaded and parsed.");
    checkAuthStatus();
});
