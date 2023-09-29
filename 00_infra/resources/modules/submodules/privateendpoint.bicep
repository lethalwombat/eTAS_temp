// https://learn.microsoft.com/en-us/azure/templates/microsoft.network/privateendpoints
// https://learn.microsoft.com/en-us/azure/templates/microsoft.network/privateendpoints/privatednszonegroups
// https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-dns

// Inputs
param name string
param location string
param tags object
param privateLinkServiceId string
param groupIds array
param deployedSubnet object
param privateDnsZoneId string

// Definition - Private Endpoint
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2022-09-01' = {
  name: '${name}-pe'
  location: location
  tags: tags
  properties: {
    customNetworkInterfaceName: '${name}-pe-nic' // max length is 80 characters
    privateLinkServiceConnections: [
      {
        name: '${name}-pe'
        properties: {
          privateLinkServiceId: privateLinkServiceId
          groupIds: groupIds
        }
      }
    ]
    subnet: {
      id: deployedSubnet.id
    }
  }
}

// Definition - Private DNS Zone Group
resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-09-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${privateEndpoint.name}-config1'
        properties: {
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  }
}

// Outputs
output deployedPrivateEndpoint object = {
  type: 'Private Endpoint'
  id : privateEndpoint.id
  name : privateEndpoint.name
  debug: privateEndpoint
}

output deployedPrivateEndpointDnsZoneGroup object = {
  type: 'Private Endpoint - DNS Zone Group'
  id : privateDnsZoneGroup.id
  name : privateDnsZoneGroup.name
  debug: privateDnsZoneGroup
}
