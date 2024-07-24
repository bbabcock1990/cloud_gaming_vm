# Cloud Gaming VM

A cloud gaming VM deployment in Azure.

## Overview

This project provides a deployment setup for a cloud gaming virtual machine (VM) in Azure. It leverages Azure's infrastructure to create a scalable and efficient environment for cloud gaming.

## Features

- **Automated Deployment**: Uses Bicep and PowerShell scripts for automated deployment.
- **Scalability**: Easily scalable to meet the demands of multiple users.
- **High Performance**: Optimized for low latency and high performance gaming.

## Prerequisites

- An Azure account
- Basic knowledge of Azure services
- Familiarity with Bicep and PowerShell

## Getting Started

1. **Clone the repository**:
    ```bash
    git clone https://github.com/bbabcock1990/cloud_gaming_vm.git
    cd cloud_gaming_vm
    ```

2. **Deploy the VM**:
    
    Option 1:
    - Run the deployment by selecting the "Deploy to Azure" Button.

    [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fbbabcock1990%2Fcloud_gaming_vm%2Fmain%2Fmain.json)
   
   Option 2:
    - Ensure you have the Azure CLI installed and logged in.
    - Run the deployment script:
    ```bash
    az deployment group create --resource-group <your-resource-group> --template-file main.bicep --parameters @main.bicepparam
    ```

## Repository Structure

- **Modules**: Contains reusable Bicep modules.
- **Scripts**: PowerShell scripts for various deployment tasks.
- **main.bicep**: Main Bicep template for VM deployment.
- **main.json**: Main ARM template for VM deployment (Portal).

## License

This project is licensed under the GPL-3.0 License. See the LICENSE file for more details.

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request.

## Contact

For any questions or issues, please open an issue in the repository.
