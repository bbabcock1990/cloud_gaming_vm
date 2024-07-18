// Parameters
param name string
param nsg string

// Resource
resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: '${name}-vnet'
  location: az.resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: ['10.0.0.0/24']
    }
    subnets: [
      {
        name: '${name}-subnet'
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id:nsg
          }
        }
      }
    ]
  }
}

// Outputs
output virtualNetworkId string = vnet.id 
output virtualNetworkName string = vnet.name
