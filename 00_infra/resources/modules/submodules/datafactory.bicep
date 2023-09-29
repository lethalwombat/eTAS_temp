// https://learn.microsoft.com/en-us/azure/templates/microsoft.datafactory/factories
// https://learn.microsoft.com/en-us/azure/templates/microsoft.datafactory/2018-06-01/factories/managedvirtualnetworks
// https://learn.microsoft.com/en-us/azure/templates/microsoft.datafactory/factories/integrationruntimes
// https://learn.microsoft.com/en-us/azure/templates/microsoft.datafactory/2018-06-01/factories/managedvirtualnetworks/managedprivateendpoints

// Input
param name string
param location string
param tags object
param publicNetworkAccess string
param identityType string
param deployedSqlServer object
param deployedKeyVault object
param deployedRawLake object
param deployedCuratedLake object
param privateEndpointParams object
param isPrivateEndpointEnabled bool
param execDateTime string = utcNow()

// Definition - Data Factory
resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    publicNetworkAccess: publicNetworkAccess
  }
  identity: {
    type: identityType
  }
}

// Definition - Managed Virtual Network
resource dataFactoryMvnet 'Microsoft.DataFactory/factories/managedVirtualNetworks@2018-06-01' = {
  parent: dataFactory
  name: 'default' // cannot rename
  properties: {}
}

// Config - Integration Runtimes
var runtimeSettings = [
  {
    name: 'runtime-${location}-mvnet'
    typeProperties: {
      computeProperties: {
        location: 'AutoResolve'
        dataFlowProperties: {
          computeType: 'General'
          coreCount: 8
          timeToLive: 10
          cleanup: false
        }
        pipelineExternalComputeScaleProperties: {
          timeToLive: 60
        }
      }
    }
  }
  {
    name: 'AutoResolveIntegrationRuntime'
    typeProperties: {
      computeProperties: {
        location: 'AutoResolve'
        dataFlowProperties: {
          computeType: 'General'
          coreCount: 8
          timeToLive: 0
        }
      }
    }
  }
]

// Definition - Intergation Runtimes
resource runtimeMvnet 'Microsoft.DataFactory/factories/integrationRuntimes@2018-06-01' = [for (runtimeSetting, i) in runtimeSettings: {
  parent: dataFactory
  dependsOn: [
    dataFactoryMvnet
  ]
  name:runtimeSetting.name
  properties: {
    type:'Managed'
    typeProperties: runtimeSetting.typeProperties
    managedVirtualNetwork: {
      type: 'ManagedVirtualNetworkReference'
      referenceName: 'default'
    }
  }
}]

// Config - Managed Private Endpoints
// Note: Requires manual approval within Azure
var mpeLinks = [
  {
    id: deployedKeyVault.id
    name: 'ingest-vault-mpe'
    groupId: 'vault'
    fqdns: '${deployedKeyVault.name}.vaultcore.azure.net'
  }  
  {
    id: deployedSqlServer.id
    name: 'sql-server-mpe'
    groupId: 'sqlServer'
    fqdns: '${deployedSqlServer.name}.${az.environment().suffixes.sqlServerHostname}'
  }
  {
    id: deployedRawLake.id
    name: 'datalake-raw-mpe'
    groupId: 'dfs'
    fqdns: '${deployedRawLake.name}.${az.environment().suffixes.storage}'
  }
  {
    id: deployedCuratedLake.id
    name: 'datalake-cur-mpe'
    groupId: 'dfs'
    fqdns: '${deployedCuratedLake.name}.${az.environment().suffixes.storage}'
  }
]

// Definition - Managed Private Endpoints
resource mpe 'Microsoft.DataFactory/factories/managedVirtualNetworks/managedPrivateEndpoints@2018-06-01' = [for (mpeLink, i) in mpeLinks:{
  parent: dataFactoryMvnet
  name: mpeLink.name
  properties: {
    privateLinkResourceId: mpeLink.id
    groupId: mpeLink.groupId
    fqdns: [
      mpeLink.fqdns
    ]
  }
}]

// Config - Private Endpoints
var privateEndpointsBase = (isPrivateEndpointEnabled) ? [
  {
    name: '${dataFactory.name}-df'
    id: dataFactory.id
    groupIds: ['dataFactory']
    privateDnsZoneId: resourceId(privateEndpointParams.subscriptionId, privateEndpointParams.networkResourceGroup, 'Microsoft.Network/privateDnsZones', 'privatelink.datafactory.azure.net')
  }
] : []

var privateEndpoints = concat(privateEndpointsBase, (isPrivateEndpointEnabled && publicNetworkAccess == 'Enabled') ? [
  {
    name: '${dataFactory.name}-portal'
    id: dataFactory.id
    groupIds: ['portal']
    privateDnsZoneId: resourceId(privateEndpointParams.subscriptionId, privateEndpointParams.networkResourceGroup, 'Microsoft.Network/privateDnsZones', 'privatelink.adf.azure.com')
  }
] : [])

// Provision - Private Endpoints
module privateEndpoint 'privateendpoint.bicep' = [for (pe, i) in privateEndpoints: {
  name: 'peModule-df-${pe.groupIds[0]}-${i}_${execDateTime}'
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
output deployedDataFactory object = {
  type: 'Data Factory'
  id : dataFactory.id
  name : dataFactory.name
  debug: dataFactory
}
  
output deployedManagedVnet object = {
  type: 'Data Factory - Managed Virtual Network'
  id : dataFactoryMvnet.id
  name : dataFactoryMvnet.name
  debug: dataFactoryMvnet
}

output deployedRuntimeMvnets array = [for (runtimeSetting, i) in runtimeSettings: {
  type: 'Data Factory - Integration Runtime'
  id: runtimeMvnet[i].id
  name: runtimeMvnet[i].name
  debug: runtimeMvnet[i]
}]

output deployedMpes array = [for (mpeLink, i) in mpeLinks: {
  type: 'Data Factory - Managed Private Endpoints'
  id: mpe[i].id
  name: mpe[i].name
  debug: mpe[i]
}]

output deployedPrivateEndpoints array = [for (pe, i) in privateEndpoints: {
  privateEndpoint: privateEndpoint[i].outputs.deployedPrivateEndpoint
}]

output deployedPrivateEndpointDnsZoneGroups array = [for (pe, i) in privateEndpoints: {
  privateEndpoint: privateEndpoint[i].outputs.deployedPrivateEndpointDnsZoneGroup
}]
