// https://learn.microsoft.com/en-us/azure/templates/microsoft.databricks/2023-02-01/workspaces

// Input
param name string
param location string
param tags object
param publicNetworkAccess string
param namePrefix string
param isPrivateEndpointEnabled bool
param privateEndpointParams object
param execDateTime string = utcNow()

// Definition - Databricks
resource databricks 'Microsoft.Databricks/workspaces@2023-02-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: 'standard'
  }
  properties: {
    publicNetworkAccess: publicNetworkAccess
    managedResourceGroupId: subscriptionResourceId('Microsoft.Resources/resourceGroups', '${namePrefix}-databricks-rg')
    parameters: {
      enableNoPublicIp: {
        value: (isPrivateEndpointEnabled) ? true : false
      }
    }
  }
}

// Config - Private Endpoints
var privateEndpoints = (isPrivateEndpointEnabled) ? [
  {
    name: '${databricks.name}-auth'
    id: databricks.id
    groupIds: ['databricks_ui_api']
    privateDnsZoneId: resourceId(privateEndpointParams.subscriptionId, privateEndpointParams.networkResourceGroup, 'Microsoft.Network/privateDnsZones', 'privatelink.azuredatabricks.net')
  }
  {
    name: '${databricks.name}-auth'
    id: databricks.id
    groupIds: ['browser_authentication']
    privateDnsZoneId: resourceId(privateEndpointParams.subscriptionId, privateEndpointParams.networkResourceGroup, 'Microsoft.Network/privateDnsZones', 'privatelink.azuredatabricks.net')
  }
] : []

// Provision - Private Endpoints
module privateEndpoint 'privateendpoint.bicep' = [for (pe, i) in privateEndpoints: {
  name: 'peModule-${pe.name}-${i}_${execDateTime}'
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
output deployedDatabricks object = {
  type: 'Databricks'
  id : databricks.id
  name : databricks.name
  debug: databricks
}

output deployedPrivateEndpoints array = [for (pe, i) in privateEndpoints: {
  privateEndpoint: privateEndpoint[i].outputs.deployedPrivateEndpoint
}]

output deployedPrivateEndpointDnsZoneGroups array = [for (pe, i) in privateEndpoints: {
  privateEndpoint: privateEndpoint[i].outputs.deployedPrivateEndpointDnsZoneGroup
}]
