targetScope = 'subscription'

@minLength(3)
@maxLength(16)
param namePrefix string
param location string = deployment().location

// Pass in AAD App information
@minLength(36)
@maxLength(36)
param AADClientId string

@minLength(34)
@maxLength(34)
@secure()
param AADClientSecret string

param AADUser string
param AADObjectId string
param tenantId string
param sqlAdminLogin string
param sqlAdminLoginPassword string

resource myResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${namePrefix}-rg'
  location: location
}

module frontendHostingStorageDeploy 'frontend_hosting_storage.bicep' = {
  name: 'frontendHostingStorageDeploy'
  scope: myResourceGroup
  params: {
    storagePrefix: namePrefix
  }
}

var applicationIdUri = 'api://${frontendHostingStorageDeploy.outputs.domain}/${AADClientId}'
module simpleAuthWebAppDeploy 'simple_auth_webapp.bicep' = {
  name: 'simpleAuthWebAppDeploy'
  scope: myResourceGroup
  params: {
    simpleAuthPrefix: namePrefix
    applicationIdUri: applicationIdUri
    frontendHostingStorageEndpoint: frontendHostingStorageDeploy.outputs.endpoint
    AADClientId: AADClientId
    AADClientSecret: AADClientSecret
  }
}

// Function
module functionStorageDeploy 'function_storage.bicep' = {
  name: 'functionStorageDeploy'
  scope: myResourceGroup
  params: {
    storagePrefix: namePrefix
  }
}

module functionAppDeploy 'function_app.bicep' = {
  name: 'functionAppDeploy'
  scope: myResourceGroup
  params: {
    functionPrefix: namePrefix
    functionStorageName: functionStorageDeploy.outputs.storageAccountName
    AADClientId: AADClientId
    AADClientSecret: AADClientSecret
    tenantId: tenantId
    applicationIdUri: applicationIdUri
    frontendHostingStorageEndpoint: frontendHostingStorageDeploy.outputs.endpoint
    identityId: identityDeploy.outputs.identityId
    sqlDatabaseName: azureSqlDeploy.outputs.databaseName
    sqlEndpoint: azureSqlDeploy.outputs.sqlEndpoint
  }
}

// SQL
module azureSqlDeploy 'azure_sql.bicep' = {
  name: 'azureSqlDeploy'
  scope: myResourceGroup
  params: {
    sqlPrefix: namePrefix
    AADUser: AADUser
    AADObjectId: AADObjectId
    AADTenantId: tenantId
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminLoginPassword
  }
}

module identityDeploy 'identity.bicep' = {
  name: 'identityDeploy'
  scope: myResourceGroup
  params: {
     namePrefix: namePrefix
  }
}

output frontendHostingConfig object = {
  storageName: frontendHostingStorageDeploy.outputs.storageName
  endpoint: frontendHostingStorageDeploy.outputs.endpoint
  domain: frontendHostingStorageDeploy.outputs.domain
}
output simpleAuthConfig object = {
  skuName: simpleAuthWebAppDeploy.outputs.skuName
  endpoint: simpleAuthWebAppDeploy.outputs.endpoint
}

output functionConfig object = {
  functionAppName: functionAppDeploy.outputs.functionAppName
  storageAccountName: functionStorageDeploy.outputs.storageAccountName
  appServicePlanName: functionAppDeploy.outputs.appServicePlanName
  functionEndpoint: functionAppDeploy.outputs.functionEndpoint
}

output azureSqlConfig object = {
  sqlEndpoint: azureSqlDeploy.outputs.sqlEndpoint
  databaseName: azureSqlDeploy.outputs.databaseName
}
output identityConfig object = {
  identityName: identityDeploy.outputs.identityName
  identityId: identityDeploy.outputs.identityId
  identity: identityDeploy.outputs.identity
}
