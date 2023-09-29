// Inputs
@minLength(2)
@maxLength(60)
param namePrefix string
@minLength(1)
@maxLength(20)
param keyVaultNamePrefix string
param location string = resourceGroup().location
param tags object
param ingestParams object
param deployedRawLake object
param deployedCuratedLake object
param platformParams object
param privateEndpointParams object
param execDateTime string = utcNow()

// Config - Required Databases
var sqlDatabaseStreaming = (platformParams.isStreamingEnabled == true) ? ['referencedb'] : []
var sqlDatabases = concat(sqlDatabaseStreaming, (platformParams.isDataFactoryEnabled == true) ? ['controldb'] : [])

// Provision - SQL Server (Control DB / Reference DB)
module sqlServer 'submodules/sqlserver.bicep' = if (empty(sqlDatabases) == false) {
  name: 'sqlServerModule_${execDateTime}'
  params: {
    name: '${namePrefix}-sqlserver1'
    location: location
    tags: tags
    publicNetworkAccess: ingestParams.publicNetworkAccess
    identityType: 'SystemAssigned'
    adminLogin: ingestParams.adminLogin
    adminSid: ingestParams.adminSid
    adminTenantId: ingestParams.adminTenantId
    databases: sqlDatabases
    requestedBackupStorageRedundancy: ingestParams.requestedBackupStorageRedundancy
    privateEndpointParams: privateEndpointParams
    isPrivateEndpointEnabled: true
  }
}

// Provision - Stream Analytics
module streamAnalytics 'submodules/streamanalytics.bicep' = if (platformParams.isStreamingEnabled == true) {
  name: 'streamAnalyticsModule_${execDateTime}'
  params: {
    name: '${namePrefix}-streamAnalytics1'
    location: location
    tags: tags
    sku: 'Standard'
    identityType: 'SystemAssigned'
    jobType: 'Cloud'
  }
}

// Provision - Event Hub
module eventHub 'submodules/eventhub.bicep' = if (platformParams.isStreamingEnabled == true) {
  name: 'eventHubModule_${execDateTime}'
  params: {
    namespace: '${namePrefix}-eventHubNamespace1'
    location: location
    tags: tags
    sku: 'Standard'
    identityType: 'SystemAssigned'
  }
}

// Config - Required Key Vaults
var keyVaultNamesStreaming = (platformParams.isStreamingEnabled == true) ? ['${keyVaultNamePrefix}-eh-kv1'] : []
var keyVaultNamesDataFactory = concat(keyVaultNamesStreaming, (platformParams.isDataFactoryEnabled == true) ? ['${keyVaultNamePrefix}-df-kv1'] : [])
var keyVaultNames = concat(keyVaultNamesDataFactory, (platformParams.isDatabricksEnabled == true) ? ['${keyVaultNamePrefix}-db-kv1'] : [])

// Provision - Key Vaults
module keyVault 'submodules/keyvault.bicep' = [for (name, i) in keyVaultNames:{
  name: 'keyVaultModule${i}_${execDateTime}'
  params: {
    name: name
    location: location
    tags: tags
    publicNetworkAccess: ingestParams.publicNetworkAccess
    adminTenantId: ingestParams.adminTenantId
    privateEndpointParams: privateEndpointParams
    isPrivateEndpointEnabled: true
  }
}]

// Provision - Data Factory
module dataFactory 'submodules/datafactory.bicep' = if (platformParams.isDataFactoryEnabled == true) {
  name: 'dataFactoryModule_${execDateTime}'
  params: {
    name: '${namePrefix}-datafactory1'
    location: location
    tags: tags
    publicNetworkAccess: ingestParams.publicNetworkAccess
    identityType: 'SystemAssigned'
    deployedSqlServer: sqlServer.outputs.deployedSqlServer
    deployedKeyVault: keyVault[0].outputs.deployedKeyVault // Data Factory Key Vault
    deployedRawLake: deployedRawLake
    deployedCuratedLake: deployedCuratedLake
    privateEndpointParams: privateEndpointParams
    isPrivateEndpointEnabled: true
  }
}

// Provision - Databricks
module databricks 'submodules/databricks.bicep' = if (platformParams.isDatabricksEnabled == true) {
  name: 'databricksModule_${execDateTime}'
  params: {
    name: '${namePrefix}-databricks1'
    location: location
    tags: tags
    publicNetworkAccess: ingestParams.publicNetworkAccess
    namePrefix: namePrefix
    privateEndpointParams: privateEndpointParams
    isPrivateEndpointEnabled: false // only available on premium license
  }
}

// Outputs
output deployedDataFactory object = platformParams.isDataFactoryEnabled ? dataFactory.outputs.deployedDataFactory : {}
output deployedSqlServer object = (empty(sqlDatabases) == false) ? sqlServer.outputs.deployedSqlServer : {}
output deployedEventHub object = platformParams.isStreamingEnabled ? eventHub.outputs.deployedEventHub : {}

output deployedKeyVault array = [for (keyVaultName, i) in keyVaultNames: {
  id: keyVault[i].outputs.deployedKeyVault.id
  name: keyVault[i].outputs.deployedKeyVault.name
  debug: keyVault[i].outputs.deployedKeyVault
}]
