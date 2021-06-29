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

// frontend hosting plugin
module frontendHostingDeploy 'frontend_hosting.bicep' = {
  name: 'frontendHostingDeploy'
  scope: myResourceGroup
  params: {
    storagePrefix: namePrefix
  }
}

var applicationIdUri = 'api://${frontendHostingDeploy.outputs.domain}/${AADClientId}'
// simple auth plugin
module simpleAuthDeploy 'simple_auth.bicep' = {
  name: 'simpleAuthWebAppDeploy'
  scope: myResourceGroup
  params: {
    simpleAuthPrefix: namePrefix
  }
}
module simpleAuthConfigDeploy 'simple_auth_postconfig.bicep' = {
  name: 'simpleAuthConfigDeploy'
  scope: myResourceGroup
  params: {
    applicationIdUri: applicationIdUri
    frontendHostingStorageEndpoint: frontendHostingDeploy.outputs.endpoint
    AADClientId: AADClientId
    AADClientSecret: AADClientSecret
    simpleAuthWebAPPName: simpleAuthDeploy.outputs.webAppName
    tenantId: tenantId
  }
}

// Function plugin
module functionDeploy 'function.bicep' = {
  name: 'functionDeploy'
  scope: myResourceGroup
  params: {
    functionPrefix: namePrefix
  }
}
module functionConfigDeploy 'function_postconfig.bicep' = {
  name: 'functionConfigDeploy'
  scope: myResourceGroup
  params: {
    AADClientId: AADClientId
    AADClientSecret: AADClientSecret
    tenantId: tenantId
    applicationIdUri: applicationIdUri
    frontendHostingStorageEndpoint: frontendHostingDeploy.outputs.endpoint
    identityId: identityDeploy.outputs.identityId
    sqlDatabaseName: azureSqlDeploy.outputs.databaseName
    sqlEndpoint: azureSqlDeploy.outputs.sqlEndpoint
    functionStorageName: functionDeploy.outputs.storageAccountName
    functionAppEndpoint: functionDeploy.outputs.functionEndpoint
    functionAppName: functionDeploy.outputs.functionAppName
  }
}

// Azure SQL plugin
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

// identity plugin
module identityDeploy 'identity.bicep' = {
  name: 'identityDeploy'
  scope: myResourceGroup
  params: {
    namePrefix: namePrefix
  }
}

output frontendHosting_storageName string = frontendHostingDeploy.outputs.storageName
output frontendHosting_endpoint string = frontendHostingDeploy.outputs.endpoint
output frontendHosting_domain string = frontendHostingDeploy.outputs.domain

output simpleAuth_skuName string = simpleAuthDeploy.outputs.skuName
output simpleAuth_endpoint string = simpleAuthDeploy.outputs.endpoint

output function_functionAppName string = functionDeploy.outputs.functionAppName
output function_storageAccountName string = functionDeploy.outputs.storageAccountName
output function_appServicePlanName string = functionDeploy.outputs.appServicePlanName
output function_functionEndpoint string = functionDeploy.outputs.functionEndpoint

output azureSql_sqlEndpoint string = azureSqlDeploy.outputs.sqlEndpoint
output azureSql_databaseName string = azureSqlDeploy.outputs.databaseName

output identity_identityName string = identityDeploy.outputs.identityName
output identity_identityId string = identityDeploy.outputs.identityId
output identity_identity string = identityDeploy.outputs.identity
