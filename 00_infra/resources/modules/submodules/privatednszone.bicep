// https://learn.microsoft.com/en-us/azure/templates/microsoft.network/privatednszones
// https://learn.microsoft.com/en-us/azure/templates/microsoft.network/privatednszones/virtualnetworklinks

// Input
param name string
param tags object
param location string
param vnet object

// Definition - Private DNS Zone
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: name
  tags: tags
  location: location
}

// Definition - Vnet Links
resource dnsVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: '${name}-${vnet.name}-link'
  tags: tags
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

// Outputs
output deployedPrivateDnsZone object = {
  type: 'Private DNS Zone'
  id : privateDnsZone.id
  name : privateDnsZone.name
  debug: privateDnsZone
}

output deployedDnsVnetLink object = {
  type: 'Private DNS Zone - Virtual Network Link'
  id : dnsVnetLink.id
  name : dnsVnetLink.name
  debug: dnsVnetLink
}
