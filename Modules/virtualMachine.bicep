// Parameters
param vnetName string
param subnetName string
param resourceGroup string
param imagePublisher string
param imageOffer string
param windowsOSVersion string 
param size string
param name string
param adminUsername string
@secure()
param adminPassword  string
param installSteam bool
param installSunshine bool

// Variables
var subnetId = resourceId(resourceGroup,'Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)

// Resources
resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: '${name}-pip'
  location: az.resourceGroup().location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: '${name}-nic'
  location: az.resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetId
          }
          publicIPAddress: {
            id: publicIPAddress.id
          }
        }
      }
    ]
    enableAcceleratedNetworking:true
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: '${name}-vm'
  location: az.resourceGroup().location
  properties: {
    hardwareProfile: {
      vmSize: size
    }
    proximityPlacementGroup: {
      id: proximityGroup.id
    }
    osProfile: {
      computerName: name
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: windowsOSVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        name: '${name}-osdisk'
        diffDiskSettings:{
          option: 'Local'
          placement: 'ResourceDisk'
        }
        caching: 'ReadOnly'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
    licenseType: 'Windows_Client'
    priority: 'Spot'
    evictionPolicy: 'Delete'
    billingProfile: {
      maxPrice: -1
    }
  }
}

resource customScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2024-03-01' = {
  name: '${name}-script-deployment'
  location: az.resourceGroup().location
  parent: vm
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/bbabcock1990/cloud_gaming_vm/main/Scripts/installPackages.ps1'
      ]
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File installPackages.ps1 -installSteam ${installSteam} -installSunshine ${installSunshine}'
    }
  }
}

resource proximityGroup 'Microsoft.Compute/proximityPlacementGroups@2024-03-01' = {
  name: '${name}-proximitygroup-deployment'
  location: az.resourceGroup().location
}

// Outputs
output vmId string = vm.id 
output vmName string = vm.name
//output publicIP string = publicIPAddress.properties.ipAddress
