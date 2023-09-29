param factoryName string
param lsDataLakeName string

resource factoryName_EXTPQ_Parquet_DS 'Microsoft.DataFactory/factories/datasets@2018-06-01' = {
  name: '${factoryName}/EXTPQ_Parquet_DS'
  properties: {
    linkedServiceName: {
      referenceName: lsDataLakeName
      type: 'LinkedServiceReference'
    }
    parameters: {
      extpq_Container: {
        type: 'string'
      }
      extpq_Folder: {
        type: 'string'
      }
      extpq_FileName: {
        type: 'string'
      }
    }
    folder: {
      name: 'EXTPQ'
    }
    annotations: []
    type: 'Parquet'
    typeProperties: {
      location: {
        type: 'AzureBlobFSLocation'
        fileName: {
          value: '@dataset().extpq_FileName'
          type: 'Expression'
        }
        folderPath: {
          value: '@dataset().extpq_Folder'
          type: 'Expression'
        }
        fileSystem: {
          value: '@dataset().extpq_Container'
          type: 'Expression'
        }
      }
      compressionCodec: 'snappy'
    }
    schema: []
  }
}
