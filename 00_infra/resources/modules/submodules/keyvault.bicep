// https://learn.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults

// Inputs
param name string
param location string
param tags object
param publicNetworkAccess string
param adminTenantId string
param privateEndpointParams object
param isPrivateEndpointEnabled bool
param execDateTime string = utcNow()

// Definition - Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    publicNetworkAccess: publicNetworkAccess
    sku: {
      family: 'A'
      name: 'standard'
    }
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'None'
    }
    tenantId: adminTenantId
    accessPolicies: []
    enableRbacAuthorization: true
  }
}

// Definition - Private Endpoint
module privateEndpoint 'privateendpoint.bicep' = if (isPrivateEndpointEnabled) {
  name: '${keyVault.name}-vault_${execDateTime}'
  params: {
    name: '${keyVault.name}-vault'
    location: location
    tags: tags
    privateLinkServiceId: keyVault.id
    groupIds: ['vault']
    deployedSubnet: privateEndpointParams.subnet
    privateDnsZoneId: resourceId(privateEndpointParams.subscriptionId, privateEndpointParams.networkResourceGroup, 'Microsoft.Network/privateDnsZones', 'privatelink.vaultcore.azure.net')
  }
}

// Outputs
output deployedKeyVault object = {
  type: 'Key Vault'
  id : keyVault.id
  name : keyVault.name
  debug: keyVault
}

output deployedPrivateEndpoints object = privateEndpoint.outputs.deployedPrivateEndpoint
output deployedPrivateEndpointDnsZoneGroup object = privateEndpoint.outputs.deployedPrivateEndpointDnsZoneGroup
