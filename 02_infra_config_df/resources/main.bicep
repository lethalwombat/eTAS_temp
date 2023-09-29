param factoryName string
param storageAccount string
param sqlServer string
param synapseName string
param execDateTime string = utcNow()

var storageUrl = environment().suffixes.storage
var sqlServerHostName = environment().suffixes.sqlServerHostname
var sqlServerDb = 'controldb'
var sqlSynapseDb = 'test1'
var sqlDatabaseConnectionString = 'Integrated Security=False;Encrypt=True;Connection Timeout=30;Data Source=${sqlServer}${sqlServerHostName};Initial Catalog=${sqlServerDb}'
var sqlDatabaseSynapseConnectionString = 'Integrated Security=False;Encrypt=True;Connection Timeout=30;Data Source=${synapseName}-ondemand.sql.azuresynapse.net;Initial Catalog=${sqlSynapseDb}'

// Linked services

// Datalake
module lsDatalake 'modules/linked_services/ls_datalake.bicep' = {
  name: 'linkedServiceDataLake_${execDateTime}'
  params: {
    factoryName: factoryName
    lsName: 'ls_azdatalake'
    typeProperties: {
      url: 'https://${storageAccount}.dfs.${storageUrl}}/'
    }
  }
}

// Azure SQL Database
module lsSqlDatabase 'modules/linked_services/ls_azuresqldatabase.bicep' = {
  name: 'linkedServiceSqlDatabase_${execDateTime}'
  params: {
    factoryName: factoryName
    lsName: 'ls_azsqldb_metadatacontroldb'
    typeProperties: {
      connectionString: sqlDatabaseConnectionString
    }
  }
}

// Synapse
module lsSynapse 'modules/linked_services/ls_synapse.bicep' = {
  name: 'linkedServiceSynapse_${execDateTime}'
  params: {
    factoryName: factoryName
    lsName: 'ls_synapsesqlondemand_gen01'
    typeProperties: {
      connectionString: sqlDatabaseSynapseConnectionString
    }
  }
}


// Datasets

module cetasBinaryDs 'modules/datasets/cetas_binary_ds.bicep' = {
  name: 'cetasBinaryDs_${execDateTime}'
  params: {
    factoryName: factoryName
    lsDataLakeName: lsDatalake.outputs.deployedLinkedService.name
  }
}

module extpqParquetDs 'modules/datasets/extpq_parquet_ds.bicep' = {
  name: 'extpqParquetDs_${execDateTime}'
  params: {
    factoryName: factoryName
    lsDataLakeName: lsDatalake.outputs.deployedLinkedService.name
  }
}
