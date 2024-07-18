// Scope
targetScope = 'subscription'

// Parameters
param name string
param location string

// Resource
resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: '${name}-rg'
  location: location
}

// Outputs
output resourceGroupId string = resourceGroup.id 
output resourceGroupName string = resourceGroup.name
