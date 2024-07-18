// Parameters
param name string
param clientIP string

// Resource
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-11-01'= {
  name: '${name}-nsg'
  location: az.resourceGroup().location
  properties: {
    securityRules: [
      {
        name: 'MyClientIP'
        properties: {
          access: 'allow'
          description: 'allow-my-client-ip'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
          direction: 'Inbound'
          priority: 100
          protocol: '*'
          sourceAddressPrefix: clientIP 
          sourcePortRange: '*'
        }
      }
    ]
  }
}

// Outputs
output nsgId string = nsg.id
output nsgName string = nsg.name
