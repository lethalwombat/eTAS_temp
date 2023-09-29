// Input
param factoryName string
param lsName string
param typeProperties object

// Definition - Linked Service to Synapse for Azure Data Factory
resource ls 'Microsoft.DataFactory/factories/linkedServices@2018-06-01' = {
  name: '${factoryName}/${lsName}'
  properties: {
    annotations: []
    type: 'AzureSqlDW'
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


// resource factoryName_ls_synapsesqlondemand_gen01 'Microsoft.DataFactory/factories/linkedServices@2018-06-01' = {
//   name: '${factoryName}/ls_synapsesqlondemand_gen01'
//   properties: {
//     annotations: []
//     type: 'AzureSqlDW'
//     typeProperties: {
//       connectionString: ls_synapsesqlondemand_gen01_connectionString
//     }
//   }
//   dependsOn: []
// }
