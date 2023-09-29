// Inputs
@minLength(2)
@maxLength(60)
param namePrefix string
param location string = resourceGroup().location
param tags object
param networkParams object
param platformParams object
param execDateTime string = utcNow()

// Config - Network Security Groups
var nsgNames = [
  '${namePrefix}-nsg'
]

// Provision - Network Security Groups
module networkSecurityGroup 'submodules/networksecuritygroup.bicep' = [for (nsgName, i) in nsgNames: {
  name: 'nsgModule-${i}_${execDateTime}'
  params: {
    name: nsgName
    location: location
    tags: tags
  }
}]

// Config - Vnet
var vnetName = '${namePrefix}-vnet'

var subnets = [
  {
    name: 'default'
    subnetPrefix: '${networkParams.ipRange}/${networkParams.subnetSuffix}'
  }
]

// Provision - Virtual Network
module vnet 'submodules/virtualnetwork.bicep' = {
  name: 'vnetModule_${execDateTime}'
  params: {
    name: vnetName
    networkParams: networkParams
    location: location
    tags: tags
    subnets: subnets
    nsg: networkSecurityGroup[0].outputs.deployedNetworkSecurityGroup // There is only one NSG applied to all
  }
}

// Config - private DNS zones names (DMZ)
// Note: Please make sure they comply with below link of azure zones!
// https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-dns#azure-services-dns-zone-configuration
var dnsNamePrefix = 'privatelink'

var privateDnsZonesBase = platformParams.zoneType != 'DLZ' ? [
  '${dnsNamePrefix}.dfs.${az.environment().suffixes.storage}'
  '${dnsNamePrefix}.web.${az.environment().suffixes.storage}'
  '${dnsNamePrefix}.vaultcore.azure.net'
  '${dnsNamePrefix}${az.environment().suffixes.sqlServerHostname}'
  '${dnsNamePrefix}.sql.azuresynapse.net'
] : []

var privateDnsZonesStreaming = concat(privateDnsZonesBase, (platformParams.zoneType != 'DLZ' && platformParams.isStreamingEnabled) ? ['${dnsNamePrefix}.servicebus.windows.net'] : [])
var privateDnsZonesDataFactory = concat(privateDnsZonesStreaming, (platformParams.zoneType != 'DLZ' && platformParams.isDataFactoryEnabled) ? ['${dnsNamePrefix}.adf.azure.com', '${dnsNamePrefix}.datafactory.azure.net'] : [])
var privateDnsZones = concat(privateDnsZonesDataFactory, (platformParams.zoneType != 'DLZ' && platformParams.isGovernanceEnabled) ? ['${dnsNamePrefix}.purview.azure.com', '${dnsNamePrefix}.purviewstudio.azure.com'] : [])

// TODO: Do we need to add a streaming DNZ zone for the Event Hub?

// Provision - Private DNS Zone
module privateDnsZone 'submodules/privatednszone.bicep' = [for (privateDnsZone, i) in privateDnsZones: {
  name: 'privateDnsZoneModule${i}_${execDateTime}'
  params: {
    name: privateDnsZone
    tags: tags
    location: 'global'
    vnet: vnet.outputs.deployedVnet
  }
}]

// Outputs
output deployedNsg object = networkSecurityGroup[0].outputs.deployedNetworkSecurityGroup // There is only one NSG applied to all
output deployedVnet object = vnet.outputs.deployedVnet

output deployedPrivateDnsZones array = [for (privDnsZone, i) in privateDnsZones: {
  privateDnsZone: privateDnsZone[i].outputs.deployedPrivateDnsZone
}]
