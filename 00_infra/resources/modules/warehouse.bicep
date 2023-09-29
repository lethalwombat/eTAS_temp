// Inputs
param namePrefix string
param location string = resourceGroup().location
param tags object
param warehouseParams object
param defaultDataLakeStorage object
param privateEndpointParams object
param execDateTime string = utcNow()

// Provision - Synapse
module synapse 'submodules/synapse.bicep' = {
  name: 'synapseModule_${execDateTime}'
  params: {
    name: '${namePrefix}-synapse1'
    location: location
    tags: tags
    publicNetworkAccess: warehouseParams.publicNetworkAccess
    defaultDataLakeStorage: defaultDataLakeStorage
    managedResourceGroupName: '${namePrefix}-synapse1-managed-rg'
    sqlAdministratorLogin: warehouseParams.sqlAdministratorLogin
    sqlAdministratorLoginPassword: warehouseParams.sqlAdministratorLoginPassword // This will change at go-live
    privateEndpointParams: privateEndpointParams
    isPrivateEndpointEnabled: true
  }
}

// Outputs
output deployedSynapse object = synapse.outputs.deployedSynapse
