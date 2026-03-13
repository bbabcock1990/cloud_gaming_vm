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
        name: 'Allow-Sunshine-Moonlight-TCP'
        properties: {
          access: 'Allow'
          description: 'Allow Sunshine/Moonlight TCP ports 47984-47990 from client IP'
          destinationAddressPrefix: '*'
          destinationPortRange: '47984-47990'
          direction: 'Inbound'
          priority: 100
          protocol: 'Tcp'
          sourceAddressPrefix: clientIP
          sourcePortRange: '*'
        }
      }
      {
        name: 'Allow-Sunshine-Moonlight-UDP'
        properties: {
          access: 'Allow'
          description: 'Allow Sunshine/Moonlight UDP ports 47984-47990 from client IP'
          destinationAddressPrefix: '*'
          destinationPortRange: '47984-47990'
          direction: 'Inbound'
          priority: 101
          protocol: 'Udp'
          sourceAddressPrefix: clientIP
          sourcePortRange: '*'
        }
      }
      {
        name: 'Allow-RDP'
        properties: {
          access: 'Allow'
          description: 'Allow RDP TCP port 3389 from client IP'
          destinationAddressPrefix: '*'
          destinationPortRange: '3389'
          direction: 'Inbound'
          priority: 200
          protocol: 'Tcp'
          sourceAddressPrefix: clientIP
          sourcePortRange: '*'
        }
      }
      {
        name: 'Allow-TightVNC'
        properties: {
          access: 'Allow'
          description: 'Allow TightVNC TCP port 5900 from client IP'
          destinationAddressPrefix: '*'
          destinationPortRange: '5900'
          direction: 'Inbound'
          priority: 300
          protocol: 'Tcp'
          sourceAddressPrefix: clientIP
          sourcePortRange: '*'
        }
      }
      {
        name: 'Deny-All-Inbound'
        properties: {
          access: 'Deny'
          description: 'Deny all other inbound traffic'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
          direction: 'Inbound'
          priority: 1000
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
        }
      }
    ]
  }
}

// Outputs
output nsgId string = nsg.id
output nsgName string = nsg.name
