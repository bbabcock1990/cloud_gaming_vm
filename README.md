# Cloud Gaming VM Deployment

This project provides a setup for deploying a cloud gaming virtual machine (VM) on Azure. The deployment leverages Azure infrastructure for scalable and high-performance gaming. Game streaming is faciliated via [Sunshine](https://docs.lizardbyte.dev/projects/sunshine/en/latest/about/overview.html) as the Game Server and [Moonlight](https://moonlight-stream.org/) as the Game Client.

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
- Internet Cost includes Ingress Charges for Azure. Outbound charges or Egress includes 100 GB at no cost.

The total cost of this Gaming VM to run for 5 hours is around ~1.2$

![VM Cost](./ReadMe%20Files/VM%20Cost.png)

The deployment deploys a Windows 11 22H2 VM on Azure and runs a install script that accomplishes the following:
- Blocks inbound access to the VM to the Public IP of your Moonlight client. No other inbound access is allowed.
- Installs Steam Client
- Installs Sunshine Server Client
- Installs Parsec Virtual Display Driver (This provides a 60hz refresh rate virtual display)

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

2. Fill out the Subscription, Deployment Region, Name-Prefix, VM Region, and your Moonlight Client Public IP:
![PortalImage](./ReadMe%20Files/Portal%20Deployment.png)
3. Hit Deploy

#### Option 2: Azure CLI

1. Clone the repository:

    ```bash
    git clone https://github.com/bbabcock1990/cloud_gaming_vm.git
    cd cloud_gaming_vm
    ```

2. Ensure you have the Azure CLI installed and logged in.
3. Run the deployment script:

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
