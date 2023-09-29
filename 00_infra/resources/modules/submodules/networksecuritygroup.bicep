// https://learn.microsoft.com/en-us/azure/templates/microsoft.network/networksecuritygroups

// Inputs
param name string
param location string
param tags object

// Definition - Network Security Groups
resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-09-01' = {
  name: name
  location: location
  tags: tags
}

// Outputs
output deployedNetworkSecurityGroup object = {
  type: 'Network Security Group'
  id : networkSecurityGroup.id
  name : networkSecurityGroup.name
  debug: networkSecurityGroup
} 
