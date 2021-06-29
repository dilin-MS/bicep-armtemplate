// Solution plugin provides
targetScope = 'subscription'
param namePrefix string
param location string = deployment().location
param tenantId string

// aad_app plugin provides
param AADClientId string
@secure()
param AADClientSecret string
param allowedAadIds string

// azure_sql plugin provides
param AADUser string
param AADObjectId string
param sqlAdminLogin string
@secure()
param sqlAdminLoginPassword string

resource myResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${namePrefix}-rg'
  location: location
}

solution: []
AADClientId: "param namePrefix string"

pluginA:AADClientId
pluginB:AADClientId
// Solution Plugin:
// Knows: 
//    plugins: [aad_app, frontend_hosting, function, simple_auth, azure_sql, identity]
// Context passed to all plugins:
//
// {
//   "aad_app": [
//     AADClientId,
//     AADClientSecret,
//     tenantId,
//     oAuthHost,
//     oAuthAuhotiry,
//     applicationIdUrl
//   ],
//   "frontend_hosting": [
//     storageName
//     endpoint
//     domain
//   ],
//   "simple_auth": [
//     skuName,
//     endpoint
//   ],
//   "function": {
//     "function_app": {
//       functionAppName
//       appServicePlanName
//       functionEndpoint
//     },
//     "function_storage": {

//     }
//   },
//   "azure_sql": {

//   },
//   "identity": {

//   }
//   }
// }


// frontend_hosting plugin provides
module frontendHostingStorageDeploy 'frontend_hosting_storage.bicep' = {
  name: 'frontendHostingStorageDeploy'
  scope: myResourceGroup
  params: {
    storagePrefix: namePrefix
  }
}

// aad_app plugin provides
var applicationIdUri = 'api://${frontendHostingStorageDeploy.outputs.domain}/${AADClientId}'

// simple_auth plugin provides
var simpleAuthSiteConfigs = {
  CLIENT_ID: AADClientId
  CLIENT_SECRET: AADClientSecret
  TAB_APP_ENDPOINT: frontendHostingStorageDeploy.outputs.endpoint
  IDENTIFIER_URI: applicationIdUri
  ALLOWED_APP_IDS: allowedAadIds
}
module simpleAuthWebAppDeploy 'simple_auth_webapp.bicep' = {
  name: 'simpleAuthWebAppDeploy'
  scope: myResourceGroup
  params: {
    simpleAuthPrefix: namePrefix
    appSettingFromOtherModules: simpleAuthSiteConfigs
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

// function_app plugin handles
var functionAppSiteConfigs = {
  ALLOWED_APP_IDS: allowedAadIds
  AzureWebJobsDashboard: functionStorageDeploy.outputs.storageConnectionString
  AzureWebJobsStorage: functionStorageDeploy.outputs.storageConnectionString
  WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: functionStorageDeploy.outputs.storageConnectionString
  M365_APPLICATION_ID_URI: applicationIdUri
  M365_CLIENT_ID: AADClientId
  M365_CLIENT_SECRET: AADClientSecret
  M365_TENANT_ID: tenantId  
  IDENTITY_ID: identityDeploy.outputs.identityId
  SQL_DATABASE_NAME: azureSqlDeploy.outputs.databaseName
  SQL_ENDPOINT: azureSqlDeploy.outputs.sqlEndpoint
}
var functionAppAuthAllowedAudiences = [
  AADClientId
  applicationIdUri
]
var functionAppAllowedOrigins = [
  frontendHostingStorageDeploy.outputs.endpoint
]

module functionAppDeploy 'function_app.bicep' = {
  name: 'functionAppDeploy'
  scope: myResourceGroup
  params: {
    functionPrefix: namePrefix
    AADClientId: AADClientId
    tenantId: tenantId
    functionAppSiteConfigsFromOtherModules: functionAppSiteConfigs
    functionAppAuthAllowedAudiences: functionAppAuthAllowedAudiences
    functionAppAllowedOrigins: functionAppAllowedOrigins
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

// user.custom.bicep
