// =============================================================================
// parameters/dev.bicepparam
// One file per landing zone. Copy it, change the values, deploy. Nothing else.
// =============================================================================

using '../main.bicep'

// ---------- Subscription ----------
param subscriptionAliasName = 'sub-spoke-dev-eastus'
param subscriptionDisplayName = 'Spoke Dev (East US)'
// EA example. For MCA use the billingProfiles/invoiceSections form.
param billingScope = '/providers/Microsoft.Billing/billingAccounts/1234567/enrollmentAccounts/987654'
param subscriptionWorkload = 'DevTest'
param managementGroupId = 'mg-landingzones-corp'

// ---------- RG + spoke VNet ----------
param location = 'eastus'
param resourceGroupName = 'rg-spoke-dev-eastus'
param tags = {
  environment: 'dev'
  workload: 'spoke-network'
  managedBy: 'bicep'
}

param vnetName = 'vnet-spoke-dev-eastus'
param vnetAddressPrefixes = [
  '10.20.0.0/16'
]
param subnets = [
  {
    name: 'snet-workload'
    addressPrefix: '10.20.1.0/24'
  }
  {
    name: 'snet-private-endpoints'
    addressPrefix: '10.20.2.0/24'
  }
]

// ---------- Hub (existing) for peering ----------
param hubVnetName = 'vnet-hub-prod-eastus'
param hubVnetResourceGroup = 'rg-hub-prod-eastus'
param hubVnetSubscriptionId = '00000000-0000-0000-0000-000000000000'

// ---------- Peering behaviour ----------
param allowForwardedTraffic = true
param useHubGateway = false
