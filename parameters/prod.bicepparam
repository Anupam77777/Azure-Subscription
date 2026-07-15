// =============================================================================
// parameters/prod.bicepparam
// Same template, production values. Uses the hub gateway (VPN/ExpressRoute).
// =============================================================================

using '../main.bicep'

// ---------- Subscription ----------
param subscriptionAliasName = 'sub-spoke-prod-eastus'
param subscriptionDisplayName = 'Spoke Prod (East US)'
param billingScope = '/providers/Microsoft.Billing/billingAccounts/1234567/enrollmentAccounts/987654'
param subscriptionWorkload = 'Production'
param managementGroupId = 'mg-landingzones-corp'

// ---------- RG + spoke VNet ----------
param location = 'eastus'
param resourceGroupName = 'rg-spoke-prod-eastus'
param tags = {
  environment: 'prod'
  workload: 'spoke-network'
  managedBy: 'bicep'
}

param vnetName = 'vnet-spoke-prod-eastus'
param vnetAddressPrefixes = [
  '10.30.0.0/16'
]
param subnets = [
  {
    name: 'snet-workload'
    addressPrefix: '10.30.1.0/24'
  }
  {
    name: 'snet-private-endpoints'
    addressPrefix: '10.30.2.0/24'
  }
  {
    name: 'snet-appgw'
    addressPrefix: '10.30.3.0/24'
  }
]

// ---------- Hub (existing) for peering ----------
param hubVnetName = 'vnet-hub-prod-eastus'
param hubVnetResourceGroup = 'rg-hub-prod-eastus'
param hubVnetSubscriptionId = '00000000-0000-0000-0000-000000000000'

// ---------- Peering behaviour ----------
param allowForwardedTraffic = true
param useHubGateway = true
