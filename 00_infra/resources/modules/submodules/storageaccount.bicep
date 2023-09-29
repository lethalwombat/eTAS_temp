// https://learn.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts
// https://learn.microsoft.com/en-us/azure/templates/microsoft.authorization/locks
// https://learn.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts/blobservices

// Input
param name string
param location string
param tags object
param sku string
param publicNetworkAccess string
param allowBlobPublicAccess bool
param storageLock bool
param storageRetentionDays int
param privateEndpointParams object
param isPrivateEndpointEnabled bool
param execDateTime string = utcNow()

// Definition - Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: sku
  }
  kind: 'StorageV2'
  properties: {
    publicNetworkAccess: publicNetworkAccess
    accessTier: 'Hot'
    isHnsEnabled: true
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: allowBlobPublicAccess
    allowSharedKeyAccess: false
    minimumTlsVersion: 'TLS1_2'
      routingPreference: {
      routingChoice: 'MicrosoftRouting'
    }
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'None'
    }
  }
}

// Config - Storage Locks
resource dataLakelock 'Microsoft.Authorization/locks@2020-05-01' = if (storageLock) {
  name: 'StorageAccountLock'
  scope: storageAccount
  properties: {
    level: 'CanNotDelete'
    notes: 'This lock prevents deletion of the storage account.'
  }
}

// Config - Time-based Storage Retention
resource storageRetention 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = if (storageRetentionDays > 0) {
  parent: storageAccount
  name: 'default'
   properties: {
    containerDeleteRetentionPolicy: {
      enabled: true
      days: storageRetentionDays
    }
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      allowPermanentDelete: false
      enabled: true
      days: storageRetentionDays
    }
  }
}

// Config - Private Endpoints
var privateEndpointsBase = (isPrivateEndpointEnabled) ? [
  {
    name: '${storageAccount.name}-dfs'
    id: storageAccount.id
    groupIds: ['dfs']
    privateDnsZoneId: resourceId(privateEndpointParams.subscriptionId, privateEndpointParams.networkResourceGroup, 'Microsoft.Network/privateDnsZones', 'privatelink.dfs.${az.environment().suffixes.storage}')
  }
] : []

var privateEndpoints = concat(privateEndpointsBase, (isPrivateEndpointEnabled && publicNetworkAccess == 'Enabled') ? [
  {
    name: '${storageAccount.name}-web'
    id: storageAccount.id
    groupIds: ['web']
    privateDnsZoneId: resourceId(privateEndpointParams.subscriptionId, privateEndpointParams.networkResourceGroup, 'Microsoft.Network/privateDnsZones', 'privatelink.web.${az.environment().suffixes.storage}')
  }
] : [])

// Provision - Private Endpoints
module privateEndpoint 'privateendpoint.bicep' = [for (pe, i) in privateEndpoints: {
  name: 'peModule-${name}-${pe.groupIds[0]}-${i}_${execDateTime}'
  params: {
    name: pe.name
    location: location
    tags: tags
    privateLinkServiceId: pe.id
    groupIds: pe.groupIds
    deployedSubnet: privateEndpointParams.subnet
    privateDnsZoneId: pe.privateDnsZoneId
  }
}]

// Outputs
output deployedStorageAccount object = {
  type: 'Storage Account'
  id : storageAccount.id
  name : storageAccount.name
  debug: storageAccount
}

output deployedDataLakelock object = {
  type: 'Storage Account - Data Lake Lock'
  id : storageAccount.id
  name : storageAccount.name
  debug: storageAccount
}

output deployedStorageRetention object = {
  type: 'Storage Account - Storage Retention'
  id : storageRetention.id
  name : storageRetention.name
  debug: storageRetention
}

output deployedPrivateEndpoints array = [for (pe, i) in privateEndpoints: {
  privateEndpoint: privateEndpoint[i].outputs.deployedPrivateEndpoint
}]

output deployedPrivateEndpointDnsZoneGroups array = [for (pe, i) in privateEndpoints: {
  privateEndpoint: privateEndpoint[i].outputs.deployedPrivateEndpointDnsZoneGroup
}]
