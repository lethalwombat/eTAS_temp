// Input
param factoryName string
param lsName string
param typeProperties object

// Definition - Linked Service to SQL Server for Azure Data Factory
resource ls 'Microsoft.DataFactory/factories/linkedServices@2018-06-01' = {
  name: '${factoryName}/${lsName}'
  properties: {
    annotations: []
    type: 'AzureBlobFS'
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
