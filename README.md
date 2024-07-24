# Cloud Gaming VM Deployment

This project provides a setup for deploying a cloud gaming virtual machine (VM) on Azure. The deployment leverages Azure infrastructure for scalable and high-performance gaming.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
  - [Clone the Repository](#clone-the-repository)
  - [Deploy the VM](#deploy-the-vm)
    - [Option 1: Deploy to Azure Button](#option-1-deploy-to-azure-button)
    - [Option 2: Azure CLI](#option-2-azure-cli)
- [Repository Structure](#repository-structure)
- [License](#license)
- [Contributing](#contributing)
- [Contact](#contact)

## Overview

This project automates the deployment of a cloud gaming VM on Azure using Bicep and PowerShell scripts. The deployment is optimized for low latency and high performance, making it suitable for cloud gaming.

## Features

- **Automated Deployment**: Uses Bicep and PowerShell scripts.
- **Scalability**: Easily scalable to accommodate multiple users.
- **High Performance**: Optimized for gaming with low latency.

## Prerequisites

- An Azure account
- Basic knowledge of Azure services
- Familiarity with Bicep and PowerShell

## Getting Started

### Clone the Repository

1. Clone the repository:

    ```bash
    git clone https://github.com/bbabcock1990/cloud_gaming_vm.git
    cd cloud_gaming_vm
    ```

### Deploy the VM

#### Option 1: Deploy to Azure Button

1. Click the "Deploy to Azure" button.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fbbabcock1990%2Fcloud_gaming_vm%2Fmain%2Fmain.json)

#### Option 2: Azure CLI

1. Ensure you have the Azure CLI installed and logged in.
2. Run the deployment script:

    ```bash
    az deployment group create --resource-group <your-resource-group> --template-file main.bicep --parameters @main.bicepparam
    ```

## Repository Structure

- **Modules**: Reusable Bicep modules.
- **Scripts**: PowerShell scripts for deployment tasks.
- **main.bicep**: Main Bicep template for VM deployment.
- **main.json**: Main ARM template for VM deployment via the Azure portal.

## License

This project is licensed under the GPL-3.0 License. See the [LICENSE](LICENSE) file for more details.

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request.

## Contact

For any questions or issues, please open an issue in the repository.
