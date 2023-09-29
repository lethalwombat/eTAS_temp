// https://learn.microsoft.com/en-us/azure/templates/microsoft.network/virtualnetworks

// Input
param name string
param networkParams object
param location string
param tags object
param subnets array
param nsg object

// Definition - Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2022-09-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '${networkParams.ipRange}/${networkParams.vnetSuffix}'
      ]
    }
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.subnetPrefix
        networkSecurityGroup: {
          id: nsg.id
        }
      }
    }]
  }
}

// Outputs
output deployedVnet object = {
  type: 'Virtual Network'
  id : vnet.id
  name : vnet.name
  debug: vnet
}
