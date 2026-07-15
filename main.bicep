// =============================================================================
// main.bicep  (TENANT SCOPE)
// 1) Creates a NEW subscription (alias) under a management group.
// 2) Deploys the landing zone (RG + spoke VNet + hub peering) INTO that new sub.
//
// Deploy with:  az deployment tenant create ...
// Everything is driven from the .bicepparam file — new landing zone = new file.
// =============================================================================

targetScope = 'tenant'

// ---------- Subscription creation ----------
@description('Alias name for the subscription (unique in tenant; commonly same as display name).')
param subscriptionAliasName string

@description('Display name shown in the portal.')
param subscriptionDisplayName string

@description('''Billing scope resource ID.
EA:  /providers/Microsoft.Billing/billingAccounts/{billingAccountId}/enrollmentAccounts/{enrollmentAccountId}
MCA: /providers/Microsoft.Billing/billingAccounts/{ba}/billingProfiles/{bp}/invoiceSections/{is}''')
param billingScope string

@description('Subscription workload type.')
@allowed([
  'Production'
  'DevTest'
])
param subscriptionWorkload string = 'Production'

@description('Short ID of the management group to place the new subscription under.')
param managementGroupId string

// ---------- Landing zone: RG / VNet / peering (passed through) ----------
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

// =============================================================================
// 1) Create the subscription under the target management group
// =============================================================================
resource subAlias 'Microsoft.Subscription/aliases@2021-10-01' = {
  name: subscriptionAliasName
  properties: {
    displayName: subscriptionDisplayName
    workload: subscriptionWorkload
    billingScope: billingScope
    additionalProperties: {
      managementGroupId: tenantResourceId('Microsoft.Management/managementGroups', managementGroupId)
      tags: tags
    }
  }
}

// =============================================================================
// 2) Deploy the landing zone into the newly created subscription
// =============================================================================
module landingZone 'modules/subscription-resources.bicep' = {
  name: 'lz-${resourceGroupName}'
  scope: subscription(subAlias.properties.subscriptionId)
  params: {
    location: location
    resourceGroupName: resourceGroupName
    tags: tags
    vnetName: vnetName
    vnetAddressPrefixes: vnetAddressPrefixes
    subnets: subnets
    hubVnetName: hubVnetName
    hubVnetResourceGroup: hubVnetResourceGroup
    hubVnetSubscriptionId: hubVnetSubscriptionId
    allowForwardedTraffic: allowForwardedTraffic
    useHubGateway: useHubGateway
  }
}

output subscriptionId string = subAlias.properties.subscriptionId
output resourceGroupId string = landingZone.outputs.resourceGroupId
output spokeVnetId string = landingZone.outputs.spokeVnetId
