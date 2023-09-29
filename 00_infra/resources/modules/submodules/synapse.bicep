// https://learn.microsoft.com/en-us/azure/templates/microsoft.synapse/workspaces

// Input
param name string
param location string
param tags object
param publicNetworkAccess string
param defaultDataLakeStorage object
param managedResourceGroupName string
param sqlAdministratorLogin string
@secure()
param sqlAdministratorLoginPassword string
param privateEndpointParams object
param isPrivateEndpointEnabled bool
param execDateTime string = utcNow()

// Definition - Synapse
resource synapse 'Microsoft.Synapse/workspaces@2021-06-01' = {
  name: name
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publicNetworkAccess: publicNetworkAccess
    azureADOnlyAuthentication: true
    defaultDataLakeStorage: {
      resourceId: defaultDataLakeStorage.id
      createManagedPrivateEndpoint: true
      accountUrl: 'https://${defaultDataLakeStorage.name}.dfs.${az.environment().suffixes.storage}'
      filesystem: 'synapse'
    }
    managedVirtualNetwork: 'default'
    managedResourceGroupName: managedResourceGroupName
    sqlAdministratorLogin: sqlAdministratorLogin
    sqlAdministratorLoginPassword: sqlAdministratorLoginPassword
    trustedServiceBypassEnabled: false
  }
}

// Definition - Private Endpoint
module privateEndpoint 'privateendpoint.bicep' = if (isPrivateEndpointEnabled) {
  name: 'peModule-synapse_${execDateTime}'
  params: {
    name: '${synapse.name}-sqlod'
    location: location
    tags: tags
    privateLinkServiceId: synapse.id
    groupIds: ['SqlOnDemand']
    deployedSubnet: privateEndpointParams.subnet
    privateDnsZoneId: resourceId(privateEndpointParams.subscriptionId, privateEndpointParams.networkResourceGroup, 'Microsoft.Network/privateDnsZones', 'privatelink.sql.azuresynapse.net')
  }
}

// Outputs
output deployedSynapse object = {
  type: 'Synapse Workspace'
  id : synapse.id
  name : synapse.name
  debug: synapse
}

output deployedPrivateEndpoints object = privateEndpoint.outputs.deployedPrivateEndpoint
output deployedPrivateEndpointDnsZoneGroup object = privateEndpoint.outputs.deployedPrivateEndpointDnsZoneGroup
