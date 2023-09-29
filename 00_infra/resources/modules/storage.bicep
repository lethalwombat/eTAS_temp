// Inputs
param namePrefix string
param location string = resourceGroup().location
param tags object
param storageParams object
param privateEndpointParams object
param execDateTime string = utcNow()

// Provision - Storage Account
module storageAccount 'submodules/storageaccount.bicep' = [for (name, i ) in storageParams.dataLakeNames: {
  name: 'storageModule${i}_${execDateTime}'
  params: {
    name: '${namePrefix}${name}'
    location: location
    tags: tags
    sku: storageParams.sku
    publicNetworkAccess: storageParams.publicNetworkAccess
    allowBlobPublicAccess: storageParams.allowBlobPublicAccess
    storageLock: storageParams.storageLock
    storageRetentionDays: storageParams.storageRetentionDays
    privateEndpointParams: privateEndpointParams
    isPrivateEndpointEnabled: true
  }
}]

// Outputs
output deployedStorageAccounts array = [for (dataLakeName, i) in storageParams.dataLakeNames: {
  storageAccount: storageAccount[i].outputs.deployedStorageAccount
}]
