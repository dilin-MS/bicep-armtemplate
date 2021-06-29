targetScope = 'subscription'
param namePrefix string
param location string = deployment().location
param AADClientId string
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

output frontendHosting_storageName string = frontendHostingStorageDeploy.outputs.storageName
output frontendHosting_endpoint string = frontendHostingStorageDeploy.outputs.endpoint
output frontendHosting_domain string = frontendHostingStorageDeploy.outputs.domain

output simpleAuth_skuName string = simpleAuthWebAppDeploy.outputs.skuName
output simpleAuth_endpoint string = simpleAuthWebAppDeploy.outputs.endpoint

output functionConfig_functionAppName string = functionAppDeploy.outputs.functionAppName
output functionConfig_storageAccountName string = functionStorageDeploy.outputs.storageAccountName
output functionConfig_appServicePlanName string = functionAppDeploy.outputs.appServicePlanName
output functionConfig_functionEndpoint string = functionAppDeploy.outputs.functionEndpoint

output azureSqlConfig_sqlEndpoint string =  azureSqlDeploy.outputs.sqlEndpoint
output azureSqlConfig_databaseName string =  azureSqlDeploy.outputs.databaseName

output identityConfig_identityName string =  identityDeploy.outputs.identityName
output identityConfig_identityId string =  identityDeploy.outputs.identityId
output identityConfig_identity string =  identityDeploy.outputs.identity
