// Input
param factoryName string
param lsName string
param typeProperties object

// Definition - Linked Service to Azure SQL Database for Azure Data Factory
resource ls 'Microsoft.DataFactory/factories/linkedServices@2018-06-01' = {
  name: '${factoryName}/${lsName}'
  properties: {
    annotations: [
    ]
    type: 'AzureSqlDatabase'
    typeProperties: typeProperties
    connectVia: {
      referenceName: 'AutoResolveIntegrationRuntime'
      type: 'IntegrationRuntimeReference'
    }
  }
}

// Outputs
output deployedLinkedService object = {
  name: lsName
  id: ls.id
  properties: ls.properties
}
