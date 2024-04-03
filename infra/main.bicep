targetScope = 'subscription'

// The main bicep module to provision Azure resources.
// For a more complete walkthrough to understand how this file works with azd,
// see https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/make-azd-compatible?pivots=azd-create

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@secure()
@description('PostGreSQL Server administrator password')
param postgresAdminPassword string

@secure()
@description('Rails SECRET_KEY_BASE for cryptographic signing')
param railsSecretKeyBase string

@secure()
@description('Rails RAILS_MASTER_KEY for secret encryption')
param railsMasterKey string

// Optional parameters to override the default azd resource naming conventions.
// Add the following to main.parameters.json to provide values:
// "resourceGroupName": {
//      "value": "myGroupName"
// }
@description('Resource group name')
param resourceGroupName string = ''

@description('PostgreSQL database name')
param postgresDatabaseName string = 'azure_rails_starter_production'

@description('Keyvault resource name')
param keyVaultName string = ''

@description('Azure Container Apps identity name')
param identityName string = ''

@description('If true use existing Azure Container Apps instance')
param acaExists bool = false

var abbrs = loadJsonContent('./abbreviations.json')

var tags = {
  'azd-env-name': environmentName
}

// Generate a unique token to be used in naming resources.
// Remove linter suppression after using.
#disable-next-line no-unused-vars
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

// Name of the service defined in azure.yaml
// A tag named azd-service-name with this value should be applied to the service host resource, such as:
//   Microsoft.Web/sites for appservice, function
// Example usage:
//   tags: union(tags, { 'azd-service-name': apiServiceName })
var appServiceName = 'azure-rails-starter'

// Organize resources in a resource group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

var prefix = '${environmentName}-${resourceToken}'
var railsIdentityName = !empty(identityName)
  ? identityName
  : '${abbrs.managedIdentityUserAssignedIdentities}rails-${environmentName}'
var postgresServerName = '${abbrs.dBforPostgreSQLServers}${prefix}'
var postgresAdminUser = 'admin${uniqueString(resourceGroup.id)}'

// Add resources to be provisioned below.
// A full example that leverages azd bicep modules can be seen in the todo-python-mongo template:
// https://github.com/Azure-Samples/todo-python-mongo/tree/main/infra

module railsIdentity 'identity.bicep' = {
  name: 'identity'
  scope: resourceGroup
  params: {
    name: railsIdentityName
    location: location
    tags: tags
  }
}

module logAnalyticsWorkspace 'core/monitor/loganalytics.bicep' = {
  name: 'loganalytics'
  scope: resourceGroup
  params: {
    name: '${prefix}-loganalytics'
    location: location
    tags: tags
  }
}

module postgresServer 'core/database/postgresql/flexibleserver.bicep' = {
  name: 'postgresql'
  scope: resourceGroup
  params: {
    name: postgresServerName
    location: location
    tags: tags
    sku: {
      name: 'Standard_B1ms'
      tier: 'Burstable'
    }
    storage: {
      storageSizeGB: 32
    }
    version: '14'
    administratorLogin: postgresAdminUser
    administratorLoginPassword: postgresAdminPassword
    databaseNames: [postgresDatabaseName]
    allowAzureIPsFirewall: true
    azureExtensions: ['PLPGSQL']
  }
}

module containerApps 'core/host/container-apps.bicep' = {
  name: 'container-apps'
  scope: resourceGroup
  params: {
    name: 'app'
    location: location
    tags: tags
    containerAppsEnvironmentName: '${prefix}-containerapps-env'
    containerRegistryName: '${replace(prefix, '-', '')}registry'
    logAnalyticsWorkspaceName: logAnalyticsWorkspace.outputs.name
  }
}

module keyVault './core/security/keyvault.bicep' = {
  name: 'keyvault'
  scope: resourceGroup
  params: {
    name: !empty(keyVaultName) ? keyVaultName : '${abbrs.keyVaultVaults}${resourceToken}'
    location: location
    tags: tags
    identityName: railsIdentity.outputs.name
  }
}

module keyVaultAccess './core/security/keyvault-access.bicep' = {
  name: 'keyvault-access'
  scope: resourceGroup
  params: {
    keyVaultName: keyVault.outputs.name
    principalId: railsIdentity.outputs.principalId
  }
}

module keyVaultSecretPostgresAdminPassword './core/security/keyvault-secret.bicep' = {
  name: 'keyvault-secret-postgres-admin-password'
  scope: resourceGroup
  params: {
    keyVaultName: keyVault.outputs.name
    name: 'postgres-admin-password'
    secretValue: postgresAdminPassword
  }
}

module keyVaultSecretDatabaseUrl './core/security/keyvault-secret.bicep' = {
  name: 'keyvault-secret-database-url'
  scope: resourceGroup
  params: {
    keyVaultName: keyVault.outputs.name
    name: 'database-url'
    secretValue: 'postgresql://${postgresAdminUser}:${postgresAdminPassword}@${postgresServer.outputs.POSTGRES_DOMAIN_NAME}:5432/${postgresDatabaseName}?connect_timeout=5&sslmode=require'
  }
}

module keyVaultSecretSecretKeyBase './core/security/keyvault-secret.bicep' = {
  name: 'keyvault-secret-secret-key-base'
  scope: resourceGroup
  params: {
    keyVaultName: keyVault.outputs.name
    name: 'secret-key-base'
    secretValue: railsSecretKeyBase
  }
}

module keyVaultSecretRailsMasterKey './core/security/keyvault-secret.bicep' = {
  name: 'keyvault-secret-rails-master-key'
  scope: resourceGroup
  params: {
    keyVaultName: keyVault.outputs.name
    name: 'rails-master-key'
    secretValue: railsMasterKey
  }
}

module rails 'rails.bicep' = {
  name: 'rails'
  scope: resourceGroup
  params: {
    name: replace('${take(prefix,19)}-ca', '--', '-')
    location: location
    tags: tags
    identityName: railsIdentity.outputs.name
    containerAppsEnvironmentName: containerApps.outputs.environmentName
    containerRegistryName: containerApps.outputs.registryName
    serviceName: appServiceName
    exists: acaExists
    keyVaultName: keyVault.outputs.name
  }
  dependsOn: [
    keyVaultSecretDatabaseUrl
    keyVaultSecretSecretKeyBase
    keyVaultAccess
  ]
}

// Add outputs from the deployment here, if needed.
//
// This allows the outputs to be referenced by other bicep deployments in the deployment pipeline,
// or by the local machine as a way to reference created resources in Azure for local development.
// Secrets should not be added here.
//
// Outputs are automatically saved in the local azd environment .env file.
// To see these outputs, run `azd env get-values`,  or `azd env get-values --output json` for json output.

output AZURE_LOCATION string = location
output AZURE_RESOURCE_GROUP_NAME string = resourceGroup.name
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_KEY_VAULT_NAME string = keyVault.outputs.name

output SERVICE_RAILS_IDENTITY_PRINCIPAL_ID string = rails.outputs.SERVICE_RAILS_IDENTITY_PRINCIPAL_ID
output SERVICE_RAILS_NAME string = rails.outputs.SERVICE_RAILS_NAME
output SERVICE_RAILS_URI string = rails.outputs.SERVICE_RAILS_URI
output SERVICE_RAILS_IMAGE_NAME string = rails.outputs.SERVICE_RAILS_IMAGE_NAME
output SERVICE_RAILS_DATABASE_NAME string = postgresDatabaseName

output AZURE_CONTAINER_ENVIRONMENT_NAME string = containerApps.outputs.environmentName
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerApps.outputs.registryLoginServer
output AZURE_CONTAINER_REGISTRY_NAME string = containerApps.outputs.registryName
