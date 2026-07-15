// =============================================================================
// modules/subscription-resources.bicep  (SUBSCRIPTION SCOPE)
// Runs INSIDE the newly created subscription: creates the RG, the spoke VNet,
// and both sides of the hub peering.
// =============================================================================

targetScope = 'subscription'

param location string
param resourceGroupName string
param tags object = {}

param vnetName string
param vnetAddressPrefixes array
param subnets array

param hubVnetName string
param hubVnetResourceGroup string
param hubVnetSubscriptionId string

param allowForwardedTraffic bool = true
param useHubGateway bool = false

// ---------- Resource group ----------
resource rg 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// ---------- Spoke VNet ----------
module spokeVnet 'vnet.bicep' = {
  name: 'deploy-${vnetName}'
  scope: rg
  params: {
    vnetName: vnetName
    location: location
    addressPrefixes: vnetAddressPrefixes
    subnets: subnets
    tags: tags
  }
}

// ---------- Peering: SPOKE -> HUB (spoke RG) ----------
module spokeToHub 'peering.bicep' = {
  name: 'peer-spoke-to-hub'
  scope: rg
  params: {
    localVnetName: vnetName
    remoteVnetId: resourceId(
      hubVnetSubscriptionId,
      hubVnetResourceGroup,
      'Microsoft.Network/virtualNetworks',
      hubVnetName
    )
    peeringName: '${vnetName}-to-${hubVnetName}'
    allowForwardedTraffic: allowForwardedTraffic
    allowGatewayTransit: false
    useRemoteGateways: useHubGateway
  }
  dependsOn: [
    spokeVnet
  ]
}

// ---------- Peering: HUB -> SPOKE (hub RG / hub subscription) ----------
module hubToSpoke 'peering.bicep' = {
  name: 'peer-hub-to-spoke'
  scope: resourceGroup(hubVnetSubscriptionId, hubVnetResourceGroup)
  params: {
    localVnetName: hubVnetName
    remoteVnetId: spokeVnet.outputs.vnetId
    peeringName: '${hubVnetName}-to-${vnetName}'
    allowForwardedTraffic: allowForwardedTraffic
    allowGatewayTransit: useHubGateway
    useRemoteGateways: false
  }
}

output resourceGroupId string = rg.id
output spokeVnetId string = spokeVnet.outputs.vnetId
