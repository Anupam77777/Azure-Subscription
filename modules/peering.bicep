// =============================================================================
// modules/peering.bicep  (RESOURCE GROUP SCOPE)
// Generic one-direction peering. Called twice from main.bicep (spoke->hub and
// hub->spoke) so the same module handles both sides.
// =============================================================================

@description('Name of the EXISTING local VNet on which the peering is created.')
param localVnetName string

@description('Resource ID of the REMOTE VNet to peer with.')
param remoteVnetId string

@description('Name of the peering resource.')
param peeringName string

@description('Allow VMs in the peered VNets to communicate.')
param allowVirtualNetworkAccess bool = true

@description('Allow forwarded (non-locally-originated) traffic.')
param allowForwardedTraffic bool = true

@description('Allow this VNet''s gateway to be used by the remote VNet (hub side).')
param allowGatewayTransit bool = false

@description('Use the remote VNet''s gateway (spoke side).')
param useRemoteGateways bool = false

resource localVnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: localVnetName
}

resource peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  parent: localVnet
  name: peeringName
  properties: {
    remoteVirtualNetwork: {
      id: remoteVnetId
    }
    allowVirtualNetworkAccess: allowVirtualNetworkAccess
    allowForwardedTraffic: allowForwardedTraffic
    allowGatewayTransit: allowGatewayTransit
    useRemoteGateways: useRemoteGateways
  }
}

output peeringId string = peering.id
