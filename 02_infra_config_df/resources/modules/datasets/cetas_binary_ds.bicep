param factoryName string
param lsDataLakeName string

resource factoryName_CETAS_Binary_DS 'Microsoft.DataFactory/factories/datasets@2018-06-01' = {
  name: '${factoryName}/CETAS_Binary_DS'
  properties: {
    linkedServiceName: {
      referenceName: lsDataLakeName
      type: 'LinkedServiceReference'
    }
    parameters: {
      cetas_Container: {
        type: 'string'
        defaultValue: 'transformed'
      }
      cetas_Folder: {
        type: 'string'
      }
    }
    folder: {
      name: 'CETAS'
    }
    annotations: []
    type: 'Binary'
    typeProperties: {
      location: {
        type: 'AzureBlobFSLocation'
        folderPath: {
          value: '@dataset().cetas_Folder'
          type: 'Expression'
        }
        fileSystem: {
          value: '@dataset().cetas_Container'
          type: 'Expression'
        }
      }
    }
  }
}
