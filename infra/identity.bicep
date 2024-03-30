//
// Module that creates a user assigned managed identity
//

@description('Name of the user assigned managed identity to creates')
param name string
param location string = resourceGroup().location
param tags object = {}

resource webIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: name
  location: location
  tags: tags
}

@description('Name of the created user managed identity')
output name string = webIdentity.name

@description('Principal ID of the created user managed identity')
output principalId string = webIdentity.properties.principalId
