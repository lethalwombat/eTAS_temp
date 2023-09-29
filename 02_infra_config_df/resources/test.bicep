param factoryName string = 'ts1-testing-dev-ingest-datafactory1'

@secure()
param AzureSqlDatabase1_connectionString string = 'Integrated Security=False;Encrypt=True;Connection Timeout=30;Data Source=ts1-testing-dev-ingest-sqlserver1.database.windows.net;Initial Catalog=controldb'
param ls_azdatalake_properties_typeProperties_url string = 'https://ts1testingdevraw1.dfs.core.windows.net}/'
param ingest_vault_mpe_properties_privateLinkResourceId string = '/subscriptions/5fc02796-c448-4082-9e29-aaf024a8d9ed/resourceGroups/ts1-testing-dev-rg/providers/Microsoft.KeyVault/vaults/ts1-testing-dev-df-kv1'
param ingest_vault_mpe_properties_groupId string = 'vault'
param ingest_vault_mpe_properties_fqdns array = [
  'ts1-testing-dev-df-kv1.vault.azure.net'
]
param datalake_raw_mpe_properties_privateLinkResourceId string = '/subscriptions/5fc02796-c448-4082-9e29-aaf024a8d9ed/resourceGroups/ts1-testing-dev-rg/providers/Microsoft.Storage/storageAccounts/ts1testingdevraw1'
param datalake_raw_mpe_properties_groupId string = 'dfs'
param datalake_raw_mpe_properties_fqdns array = [
  'ts1testingdevraw1.dfs.core.windows.net'
]
param datalake_cur_mpe_properties_privateLinkResourceId string = '/subscriptions/5fc02796-c448-4082-9e29-aaf024a8d9ed/resourceGroups/ts1-testing-dev-rg/providers/Microsoft.Storage/storageAccounts/ts1testingdevcur1'
param datalake_cur_mpe_properties_groupId string = 'dfs'
param datalake_cur_mpe_properties_fqdns array = [
  'ts1testingdevcur1.dfs.core.windows.net'
]
param sql_server_mpe_properties_privateLinkResourceId string = '/subscriptions/5fc02796-c448-4082-9e29-aaf024a8d9ed/resourceGroups/ts1-testing-dev-rg/providers/Microsoft.Sql/servers/ts1-testing-dev-ingest-sqlserver1'
param sql_server_mpe_properties_groupId string = 'sqlServer'
param sql_server_mpe_properties_fqdns array = [
  'ts1-testing-dev-ingest-sqlserver1.database.windows.net'
]

var factoryId = 'Microsoft.DataFactory/factories/${factoryName}'

resource factoryName_runtime_australiaeast_mvnet 'Microsoft.DataFactory/factories/integrationRuntimes@2018-06-01' = {
  name: '${factoryName}/runtime-australiaeast-mvnet'
  properties: {
    type: 'Managed'
    typeProperties: {
      computeProperties: {
        location: 'AutoResolve'
        dataFlowProperties: {
          computeType: 'General'
          coreCount: 8
          timeToLive: 10
          cleanup: false
        }
        pipelineExternalComputeScaleProperties: {
          timeToLive: 60
        }
      }
    }
    managedVirtualNetwork: {
      type: 'ManagedVirtualNetworkReference'
      referenceName: 'default'
    }
  }
  dependsOn: [
    '${factoryId}/managedVirtualNetworks/default'
  ]
}

resource factoryName_AutoResolveIntegrationRuntime 'Microsoft.DataFactory/factories/integrationRuntimes@2018-06-01' = {
  name: '${factoryName}/AutoResolveIntegrationRuntime'
  properties: {
    type: 'Managed'
    typeProperties: {
      computeProperties: {
        location: 'AutoResolve'
        dataFlowProperties: {
          computeType: 'General'
          coreCount: 8
          timeToLive: 0
        }
      }
    }
    managedVirtualNetwork: {
      type: 'ManagedVirtualNetworkReference'
      referenceName: 'default'
    }
  }
  dependsOn: [
    '${factoryId}/managedVirtualNetworks/default'
  ]
}

resource factoryName_ls_azdatalake 'Microsoft.DataFactory/factories/linkedServices@2018-06-01' = {
  name: '${factoryName}/ls_azdatalake'
  properties: {
    annotations: []
    type: 'AzureBlobFS'
    typeProperties: {
      url: ls_azdatalake_properties_typeProperties_url
    }
    connectVia: {
      referenceName: 'AutoResolveIntegrationRuntime'
      type: 'IntegrationRuntimeReference'
    }
  }
  dependsOn: [
    '${factoryId}/integrationRuntimes/AutoResolveIntegrationRuntime'
  ]
}

resource factoryName_default 'Microsoft.DataFactory/factories/managedVirtualNetworks@2018-06-01' = {
  name: '${factoryName}/default'
  properties: {}
  dependsOn: []
}

resource factoryName_default_ingest_vault_mpe 'Microsoft.DataFactory/factories/managedVirtualNetworks/managedPrivateEndpoints@2018-06-01' = {
  parent: factoryName_default
  name: 'ingest-vault-mpe'
  properties: {
    privateLinkResourceId: ingest_vault_mpe_properties_privateLinkResourceId
    groupId: ingest_vault_mpe_properties_groupId
    fqdns: ingest_vault_mpe_properties_fqdns
  }
  dependsOn: [
    '${factoryId}/managedVirtualNetworks/default'
  ]
}

resource factoryName_default_datalake_raw_mpe 'Microsoft.DataFactory/factories/managedVirtualNetworks/managedPrivateEndpoints@2018-06-01' = {
  parent: factoryName_default
  name: 'datalake-raw-mpe'
  properties: {
    privateLinkResourceId: datalake_raw_mpe_properties_privateLinkResourceId
    groupId: datalake_raw_mpe_properties_groupId
    fqdns: datalake_raw_mpe_properties_fqdns
  }
  dependsOn: [
    '${factoryId}/managedVirtualNetworks/default'
  ]
}

resource factoryName_default_datalake_cur_mpe 'Microsoft.DataFactory/factories/managedVirtualNetworks/managedPrivateEndpoints@2018-06-01' = {
  parent: factoryName_default
  name: 'datalake-cur-mpe'
  properties: {
    privateLinkResourceId: datalake_cur_mpe_properties_privateLinkResourceId
    groupId: datalake_cur_mpe_properties_groupId
    fqdns: datalake_cur_mpe_properties_fqdns
  }
  dependsOn: [
    '${factoryId}/managedVirtualNetworks/default'
  ]
}

resource factoryName_default_sql_server_mpe 'Microsoft.DataFactory/factories/managedVirtualNetworks/managedPrivateEndpoints@2018-06-01' = {
  parent: factoryName_default
  name: 'sql-server-mpe'
  properties: {
    privateLinkResourceId: sql_server_mpe_properties_privateLinkResourceId
    groupId: sql_server_mpe_properties_groupId
    fqdns: sql_server_mpe_properties_fqdns
  }
  dependsOn: [
    '${factoryId}/managedVirtualNetworks/default'
  ]
}

resource factoryName_AzureSqlDatabase1 'Microsoft.DataFactory/factories/linkedServices@2018-06-01' = {
  name: '${factoryName}/AzureSqlDatabase1'
  properties: {
    annotations: []
    type: 'AzureSqlDatabase'
    typeProperties: {
      connectionString: AzureSqlDatabase1_connectionString
    }
    connectVia: {
      referenceName: 'AutoResolveIntegrationRuntime'
      type: 'IntegrationRuntimeReference'
    }
  }
  dependsOn: [
    '${factoryId}/integrationRuntimes/AutoResolveIntegrationRuntime'
  ]
}