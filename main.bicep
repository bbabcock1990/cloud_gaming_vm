// Deploy to subscription scope
targetScope = 'subscription'

// Parameters used during deployment
param namePrefix string
param region string
param clientIP string

// Deploy the resource group
module resourceGroup 'Modules/resourceGroup.bicep' = {
  name: '${namePrefix}-rg'
  params: {
    location: region
    name: namePrefix
  }
}

// Deploy the virtual network
module virtualNetwork 'Modules/virtualNetwork.bicep' = {
  scope: az.resourceGroup('${namePrefix}-rg')
  name: '${namePrefix}-vnet'
  params: {
    name: namePrefix
    nsg: networkSecurityGroup.outputs.nsgId
  }
}

// Deploy the network security group
module networkSecurityGroup 'Modules/networkSecurityGroup.bicep' = {
  scope: az.resourceGroup('${namePrefix}-rg')
  name: '${namePrefix}-nsg'
  params: {
    clientIP: clientIP
    name: namePrefix
  }
  dependsOn:[resourceGroup]
}

// Deploy the gaming virtual machine
module virtualMachine 'Modules/virtualMachine.bicep' = {
  scope: az.resourceGroup('${namePrefix}-rg')
  name: '${namePrefix}-vm'
  params: {
    name: namePrefix
    resourceGroup: resourceGroup.name
    subnetName: '${namePrefix}-subnet'
    vnetName: virtualNetwork.name
    adminPassword: 'Westworld2024!' //Need to address security of plaintext password
    adminUsername: 'localadmin'
    size: 'Standard_NG8ads_V620_v1'
    windowsOSVersion: 'win11-22h2-pro'
    imagePublisher: 'microsoftwindowsdesktop'
    imageOffer: 'windows-11'
  }
}

// Outputs
