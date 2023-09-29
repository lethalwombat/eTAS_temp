// https://learn.microsoft.com/en-us/azure/templates/microsoft.streamanalytics/2020-03-01/streamingjobs

// Input
param name string
param location string
param tags object
param sku string
param identityType string
param jobType string

// Definition - Stream Analytics
resource streamAnalytics 'Microsoft.StreamAnalytics/streamingjobs@2020-03-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    sku: {
      name: sku
    }
    outputErrorPolicy: 'Stop'
    eventsOutOfOrderPolicy: 'Adjust'
    eventsOutOfOrderMaxDelayInSeconds: 0
    eventsLateArrivalMaxDelayInSeconds: 5
    dataLocale: 'en-US'
    jobType: jobType
  }
  identity: {
    type: identityType
  }
}

// Outputs
output deployedStorageAccount object = {
  type: 'Stream Analytics'
  id : streamAnalytics.id
  name : streamAnalytics.name
  debug: streamAnalytics
}
