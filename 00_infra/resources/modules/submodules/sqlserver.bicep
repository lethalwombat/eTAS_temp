// https://learn.microsoft.com/en-us/azure/templates/microsoft.sql/servers
// https://learn.microsoft.com/en-us/azure/templates/microsoft.sql/servers/databases
// https://learn.microsoft.com/en-us/azure/templates/microsoft.sql/servers/databases/transparentdataencryption

// Input
param name string
param location string
param tags object
param publicNetworkAccess string
param identityType string
param adminLogin string
param adminSid string
param adminTenantId string
param databases array
param requestedBackupStorageRedundancy string
param privateEndpointParams object
param isPrivateEndpointEnabled bool
param execDateTime string = utcNow()

// Definition - SQL Server
resource sqlServer 'Microsoft.Sql/servers@2021-11-01' = {
  name: name
  location: location
  tags: tags
  identity: {
    type: identityType
  }
  properties: {
    administrators: {
      administratorType: 'ActiveDirectory'
      login: adminLogin
      principalType: 'User'
      sid: adminSid
      tenantId: adminTenantId 
      azureADOnlyAuthentication: true
    }
    publicNetworkAccess: publicNetworkAccess
    minimalTlsVersion: '1.2'
  }
}

// Definition - SQL Database
resource sqlDb 'Microsoft.Sql/servers/databases@2021-11-01' = [for (database, i) in databases: {
  parent: sqlServer
  name: database
  location: location
  tags: tags
  sku: {
    name: 'GP_S_Gen5'
    tier: 'GeneralPurpose'
    family: 'Gen5'
    capacity: 4
  }
  properties: {
    requestedBackupStorageRedundancy: requestedBackupStorageRedundancy
    zoneRedundant: false
    autoPauseDelay: 60
    minCapacity: 1  
  }
}]

// Config - Enable TDE
resource sqlDbTde 'Microsoft.Sql/servers/databases/transparentDataEncryption@2021-11-01' = [for (database, i) in databases: {
  name: 'current'
  parent: sqlDb[i]
  properties: {
    state: 'Enabled'
  }
}]

// Definition - Private Endpoint
module privateEndpoint 'privateendpoint.bicep' = if (isPrivateEndpointEnabled) {
  name: 'peModule-sqlServer_${execDateTime}'
  params: {
    name: sqlServer.name
    location: location
    tags: tags
    privateLinkServiceId: sqlServer.id
    groupIds: ['sqlServer']
    deployedSubnet: privateEndpointParams.subnet
    privateDnsZoneId: resourceId(privateEndpointParams.subscriptionId, privateEndpointParams.networkResourceGroup, 'Microsoft.Network/privateDnsZones', 'privatelink${az.environment().suffixes.sqlServerHostname}')
  }
}

// Outputs
output deployedSqlServer object = {
  type: 'SQL Server'
  id : sqlServer.id
  name : sqlServer.name
  debug: sqlServer
}

output deployedDatabases array = [for (database, i) in databases: {
  type: 'SQL Server - Databases'
  id: sqlDb[i].id
  name: sqlDb[i].name
  debug: sqlDb[i]
}]

output deployedSqlTde array = [for (database, i) in databases: {
  type: 'SQL Server - Transparent Data Encryption'
  id: sqlDbTde[i].id
  name: sqlDbTde[i].name
  debug: sqlDbTde[i]
}]

output deployedPrivateEndpoints object = privateEndpoint.outputs.deployedPrivateEndpoint
output deployedPrivateEndpointDnsZoneGroup object = privateEndpoint.outputs.deployedPrivateEndpointDnsZoneGroup
