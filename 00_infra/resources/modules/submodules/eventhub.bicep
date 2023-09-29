// https://learn.microsoft.com/en-us/azure/templates/microsoft.eventhub/namespaces

// Inputs
param namespace string
param location string
param tags object
param sku string
param identityType string

// Definition - Event Hub Namespace
resource eventHubNamespace 'Microsoft.EventHub/namespaces@2021-11-01' = {
  name: namespace
  location: location
  tags: tags
  sku: {
    name: sku
    tier: sku
    capacity: 1
  }
  properties: {
    isAutoInflateEnabled: false
    maximumThroughputUnits: 0
  }
  identity: {
    type: identityType
  }
}

// Outputs
output deployedEventHub object = {
  type: 'Event Hub - Namespace'
  id: eventHubNamespace.id
  name: eventHubNamespace.name
  debug: eventHubNamespace
}
