// Deployment Scope
targetScope = 'subscription'

// Input (param.json)
@minLength(2)
@maxLength(5)
param organisation string // Name of the organisation
param project string // Name of the project
param zone string // Name of the zone, e.g assets
@allowed([
  'dev'
  'tst'
  'prd'
])
param environment string
@allowed([
  'australiaeast'
  'australiasoutheast'
  'australiacentral'
])
param location string // Deployment location
param targetSubscriptionId string // Target subscription of the deployment
param networkParams object // Network settings
param storageParams object // Storage settings
param ingestParams object // Ingestion layer settings
@secure()
param warehouseParams object // Warehouse layer settings
param releaseParams object // Tag settings (values)
param platformParamsBase object
param execDateTime string = utcNow()

// Variables

// Ensure compatibility with eMAS codebase
var platformParams = union(
  {isStreamingEnabled: false},
  {isDataFactoryEnabled: true},
  platformParamsBase
)

var tags = union(
  {Project: project},
  {Environment: environment},
  releaseParams
)
var namePrefix = '${organisation}-${zone}-${environment}'

// Resource groups
resource resourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: '${namePrefix}-rg'
  location: location
  tags: tags
}

// Network resources
module network 'modules/network.bicep' = {
  name: 'networkModule_${execDateTime}'
  scope: resourceGroup
  params: {
    namePrefix: namePrefix
    location: location
    tags: tags
    networkParams: networkParams
    platformParams: platformParams
  }
}

// Note: Please make sure they comply with below link of azure zones!
// https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-dns#azure-services-dns-zone-configuration
var dnsNamePrefix = 'privatelink'

var privateDnsZonesBase = [
  '${dnsNamePrefix}.dfs.${az.environment().suffixes.storage}'
  '${dnsNamePrefix}.web.${az.environment().suffixes.storage}'
  '${dnsNamePrefix}${az.environment().suffixes.sqlServerHostname}'
  '${dnsNamePrefix}.adf.azure.com'
  '${dnsNamePrefix}.datafactory.azure.net'
]

// Additional private DNS zones required as per the platform settings
var privateDnsZonesKeyVault = concat([], (platformParams.isKeyVaultEnabled) ? ['${dnsNamePrefix}.vaultcore.azure.net'] : [])
var privateDnsZonesSynapse = concat([], (platformParams.isSynapseEnabled) ? ['${dnsNamePrefix}.sql.azuresynapse.net'] : [])
var privateDnsZones = concat(privateDnsZonesBase, privateDnsZonesKeyVault, privateDnsZonesSynapse)


// Provision - Private DNS Zone
module privateDnsZone 'modules/submodules/privatednszone.bicep' = [for (privateDnsZone, i) in privateDnsZones: {
  name: 'privateDnsZoneModule${i}_${execDateTime}'
  scope: resourceGroup
  params: {
    name: privateDnsZone
    tags: tags
    location: 'global'
    vnet: network.outputs.deployedVnet
  }
}]

// Private Endpoint - Variables
// note: modules dependency on network to provision pivate dns ids (embedded pe's)
var privateEndpointParams = {
  subscriptionId: targetSubscriptionId
  networkResourceGroup : '${namePrefix}-rg'
  subnet: network.outputs.deployedVnet.debug.properties.subnets[0] // only 1 subnet
}

// Storage resources
module storage 'modules/storage.bicep' = {
  name: 'storageModule_${execDateTime}'
  scope: resourceGroup
  params: {
    namePrefix: '${organisation}${zone}${environment}'
    location: location
    tags: tags
    storageParams: storageParams
    privateEndpointParams: privateEndpointParams
  }
  dependsOn: [
    network
  ]
}

// Ingest resources
module ingest 'modules/ingest.bicep' = {
  name: 'ingestModule_${execDateTime}'
  scope: resourceGroup
  params: {
    namePrefix: '${namePrefix}-ingest'
    keyVaultNamePrefix: namePrefix // Key Vault name cannot be longer than 24 characters
    location: location
    tags: tags
    ingestParams: ingestParams
    deployedRawLake: storage.outputs.deployedStorageAccounts[0].storageAccount // Raw lake is first
    deployedCuratedLake: storage.outputs.deployedStorageAccounts[1].storageAccount // Curated lake is second
    platformParams: platformParams
    privateEndpointParams: privateEndpointParams
  }
  dependsOn: [
    storage
  ]
}


// Warehouse resources
module warehouse 'modules/warehouse.bicep' = if (platformParams.isSynapseEnabled == true) {
  name: 'warehouseModule_${execDateTime}'
  scope: resourceGroup
  params: {
    namePrefix: namePrefix
    location: location
    tags: tags
    warehouseParams: warehouseParams
    defaultDataLakeStorage: storage.outputs.deployedStorageAccounts[0].storageAccount // Raw data lake
    privateEndpointParams: privateEndpointParams
  }
  dependsOn: [
    ingest
  ]
}
