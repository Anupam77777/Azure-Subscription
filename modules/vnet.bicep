// =============================================================================
// modules/vnet.bicep  (RESOURCE GROUP SCOPE)
// Creates a VNet with a variable-driven list of subnets.
// =============================================================================

@description('Virtual network name.')
param vnetName string

@description('Region.')
param location string

@description('Address space, e.g. [ "10.20.0.0/16" ].')
param addressPrefixes array

@description('Subnet definitions (see main.bicep for the shape).')
param subnets array

@description('Tags.')
param tags object = {}

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
    subnets: [
      for subnet in subnets: {
        name: subnet.name
        properties: {
          addressPrefix: subnet.addressPrefix
          networkSecurityGroup: (subnet.?nsgId != null)
            ? {
                id: subnet.nsgId
              }
            : null
          serviceEndpoints: subnet.?serviceEndpoints
          delegations: subnet.?delegations
        }
      }
    ]
  }
}

output vnetId string = vnet.id
output vnetName string = vnet.name
