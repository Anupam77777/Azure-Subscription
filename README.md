# Subscription Vending → Spoke VNet + Hub Peering (Bicep + Azure DevOps)

Tenant-scoped Bicep that **creates a new subscription under a management group**,
then deploys a **resource group + spoke VNet** into it and peers that VNet
**bidirectionally** with a centralized **hub VNet**. Template-and-variable driven:
a new landing zone = one new `parameters/<name>.bicepparam` file.

## Flow

```
tenant deployment (main.bicep)
   ├── Microsoft.Subscription/aliases      -> new subscription under the MG
   └── module @ subscription(newSubId)     -> modules/subscription-resources.bicep
          ├── resourceGroups               -> the spoke RG
          ├── module vnet.bicep            -> spoke VNet + subnets
          ├── module peering.bicep         -> spoke -> hub  (spoke RG)
          └── module peering.bicep         -> hub -> spoke  (hub RG / hub sub)
```

## Structure

```
.
├── main.bicep                          # TENANT scope: sub alias + landing zone
├── bicepconfig.json
├── modules/
│   ├── subscription-resources.bicep    # SUBSCRIPTION scope: RG + VNet + peerings
│   ├── vnet.bicep                      # spoke VNet + variable-driven subnets
│   └── peering.bicep                   # generic one-direction peering (reused twice)
├── parameters/
│   ├── dev.bicepparam                  # <-- copy this to add a new landing zone
│   └── prod.bicepparam
└── pipelines/
    └── azure-pipelines.yml
```

## Deploy

```bash
az deployment tenant create \
  --name lz-manual \
  --location eastus \
  --template-file main.bicep \
  --parameters parameters/dev.bicepparam
```

`--location` is required (it's where the deployment metadata lives, not the resources).

## Required permissions (all three matter)

The service connection identity needs:

1. **Management group:** `Owner` or `Contributor` on the tenant root (or target) MG
   — tenant-scope deployment + placing the sub under the MG.
2. **Billing scope:** a subscription-creation role on the billing account —
   e.g. EA *Account Owner* on the enrollment account, or MCA *Owner/Contributor*
   on the invoice section. **Without this, sub creation fails.**
3. **Hub RG/subscription:** `Network Contributor` — for the hub→spoke peering.
   Missing this leaves a one-sided (Disconnected) peering.

## Billing scope formats

- **EA:** `/providers/Microsoft.Billing/billingAccounts/{billingAccountId}/enrollmentAccounts/{enrollmentAccountId}`
- **MCA:** `/providers/Microsoft.Billing/billingAccounts/{ba}/billingProfiles/{bp}/invoiceSections/{is}`

## Adding a new landing zone

1. `cp parameters/dev.bicepparam parameters/<name>.bicepparam`
2. Change: subscription alias/display name, `managementGroupId`, RG/VNet names,
   address space, subnets, hub details.
3. Add `<name>` to the `values:` list in `azure-pipelines.yml`, run, pick it.

## Good to know

- **Readiness race:** a brand-new subscription can take a moment before resource
  providers are registered. If the landing-zone step intermittently fails with
  "subscription not found" / RP-not-registered, re-run the pipeline (idempotent —
  the alias already exists), or split into two stages: create the sub first, then
  run `az deployment sub create` against the returned `subscriptionId`.
- For a hardened, production-grade version of this exact pattern, Microsoft ships
  the ALZ **subscription vending** Bicep module (`br/public:lz/sub-vending`), which
  also handles role assignments, budgets, and hub peering orchestration.
- Spoke and hub address spaces must not overlap.
```
