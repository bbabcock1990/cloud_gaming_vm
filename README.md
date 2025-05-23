# An Azure Cloud Gaming VM

This project provides a setup for deploying a cloud gaming virtual machine (VM) on Azure. The deployment leverages Azure infrastructure for scalable and high-performance gaming. Game streaming is faciliated via [Sunshine](https://docs.lizardbyte.dev/projects/sunshine/en/latest/about/overview.html) as the Game Server and [Moonlight](https://moonlight-stream.org/) as the Game Client.

While there a ton of cloud gaming servies already out there, myself using Geforce NOW, I find that not all games are supported on these platforms. This solution allows for a quick spin up of a cost-effective cloud gaming virtual machine that provides full desktop access, with Steam pre-installed, allowing you to install or play any game within your library.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
  - [Deploy the VM](#deploy-the-vm)
    - [Option 1: Deploy to Azure Button](#option-1-deploy-to-azure-button)
    - [Option 2: Azure CLI](#option-2-azure-cli)
- [Repository Structure](#repository-structure)
- [License](#license)
- [Contributing](#contributing)
- [Contact](#contact)

## Overview

This project automates the deployment of a cloud gaming VM on Azure using Bicep and PowerShell scripts. The deployment is optimized for low latency and high performance, making it suitable for cloud gaming. By default, the deployment leverages the 'Standard_NG8ads_V620_v1' Azure VM SKU which is a Preview SKU available only in East US 2, Europe West, and West US3.

Details on this SKU can be found here: [NGADS SKU](https://learn.microsoft.com/en-us/AZURE/virtual-machines/ngads-v-620-series)

This SKU by default is a very expense SKU and gaming on any Cloud platform can be expensive. To reduce cost and make this a viable cloud gaming option, the following features are built into the deployment:

- [Spot Pricing](https://learn.microsoft.com/en-us/azure/virtual-machines/spot-vms) (at time of writing, the cost for this VM SKU under Spot pricing deployed in East US 2 is  [~.23 cents per hour](https://cloudprice.net/?tier=spot&filter=Standard_NG8ads_V620_v1))
    - The downside here is that your VM can be evicted if needed at any given time. I've had pretty good luck on this not happening but results will vary.
- [Accelerated Networking](https://learn.microsoft.com/en-us/azure/virtual-network/accelerated-networking-overview?tabs=redhat) is enabled
    - No downside here. This provide fast downloads/uploads.
- [Empheral Disk](https://learn.microsoft.com/en-us/azure/virtual-machines/ephemeral-os-disks) are used (Empheral disk are at no cost in Azure and offer better performance)
    - The downside here is that data on the disks are not persistent. Any shutdown or removal of the VM will cause data loss.
- [Internet Cost](https://azure.microsoft.com/en-us/pricing/details/bandwidth/) includes Ingress Charges for Azure. Outbound Egress charges includes 100 GB at no cost. (.087 cents per GB after 100 GB.)

The total cost of this Gaming VM to run for 5 hours is around ~1.2$

![VM Cost](./ReadMe%20Files/VM%20Cost.png)

The deployment deploys a Windows 11 22H2 VM on Azure and runs a install script that accomplishes the following:
- Blocks inbound access to the VM to the Public IP of your Moonlight client. No other inbound access is allowed.
- Installs Steam Client (optional, controllable via `installSteam` parameter)
- Installs Sunshine Server Client (optional, controllable via `installSunshine` parameter)
- Installs Parsec Virtual Display Driver (This provides a 60hz refresh rate virtual display)

### Security Enhancements
- Downloads are now managed in a user-specific temporary directory instead of the global `C:\Temp`.
- The system will automatically schedule a reboot 1 minute after the script completes installations to ensure all changes are applied.

## Features

- **Automated Deployment**: Uses Bicep and PowerShell scripts.
- **Scalability**: Easily scalable to accommodate multiple users.
- **High Performance**: Optimized for gaming with low latency.

## Prerequisites

- An Azure Subscription (MSDN Subscriptions will not work)
- Total Regional Spot Quotas Enabled for your region/Azure VM Size
![SpotImage](./ReadMe%20Files/Spot%20Request.png)
- Basic knowledge of Azure services
- Familiarity with Azure Portal, Azure Bicep and PowerShell
- A Moonlight Client

## Getting Started

### Deploy the VM

#### Option 1: Deploy to Azure Button

1. Click the "Deploy to Azure" button.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fbbabcock1990%2Fcloud_gaming_vm%2Fmain%2Fmain.json)

2. Fill out the Subscription, Deployment Region, Name-Prefix, VM Region, and your Moonlight Client Public IP.
3. You can also customize the installation of Steam and Sunshine using the `Install Steam` and `Install Sunshine` parameters, which both default to `true` (install). Set them to `false` if you wish to skip their installation.
![PortalImage](./ReadMe%20Files/Portal%20Deployment.png)
4. Hit Review and Create --> Deploy

#### Option 2: Azure CLI

1. Clone the repository:

    ```bash
    git clone https://github.com/bbabcock1990/cloud_gaming_vm.git
    cd cloud_gaming_vm
    ```

2. Ensure you have the [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/what-is-azure-cli) installed and logged in.
3. Run the deployment script:

    az deployment group create --resource-group <your-resource-group> --template-file main.bicep --parameters @main.bicepparam
    ```
    To customize the installation of Steam or Sunshine, you can modify the `main.bicepparam` file or override parameters directly in the command line. For example, to deploy without Steam:
    ```bash
    az deployment group create --resource-group <your-resource-group> --template-file main.bicep --parameters installSteam=false # other parameters from main.bicepparam or specified here
    ```
    Similarly, for no Sunshine:
    ```bash
    az deployment group create --resource-group <your-resource-group> --template-file main.bicep --parameters installSunshine=false
    ```

## Repository Structure

- **Modules**: Reusable Bicep modules.
- **Scripts**: PowerShell scripts for deployment tasks.
- **main.bicep**: Main Bicep template for VM deployment.
- **main.json**: Main ARM template for VM deployment via the Azure portal.

## License

This project is licensed under the GPL-3.0 License. See the [LICENSE](LICENSE) file for more details.

## Testing

This project includes tests to help ensure reliability and maintainability:

- **Unit Tests**: The PowerShell script `Scripts/installPackages.ps1` has associated unit tests written using [Pester](https_pester.dev/), the standard testing framework for PowerShell. These tests mock external dependencies and verify the script's logic, parameter handling, and conditional operations. You can find the tests in `Scripts/installPackages.Pester.ps1`.
- **Integration Testing Strategy**: An integration testing strategy for the Bicep templates has been outlined. This strategy involves deploying the templates to Azure and verifying the created resources and their configuration using Azure CLI or Azure PowerShell. The goal is to ensure the end-to-end deployment works as expected.

Contributions to enhancing and expanding these tests are highly encouraged.

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request. Ensure that your changes are covered by existing tests or include new tests as appropriate.

## Contact

For any questions or issues, please open an issue in the repository.
