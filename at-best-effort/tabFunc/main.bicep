targetScope = 'subscription'
param namePrefix string
param location string = deployment().location
param AADClientId string
@secure()
param AADClientSecret string
param allowedAadIds string
param tenantId string

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

module functionStorageDeploy 'function_storage.bicep' = {
  name: 'functionStorageDeploy'
  scope: myResourceGroup
  params: {
    storagePrefix: namePrefix
  }
}

var functionAppSiteConfigs = {
  ALLOWED_APP_IDS: allowedAadIds
  AzureWebJobsDashboard: functionStorageDeploy.outputs.storageConnectionString
  AzureWebJobsStorage: functionStorageDeploy.outputs.storageConnectionString
  WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: functionStorageDeploy.outputs.storageConnectionString
  M365_APPLICATION_ID_URI: applicationIdUri
  M365_CLIENT_ID: AADClientId
  M365_CLIENT_SECRET: AADClientSecret
  M365_TENANT_ID: tenantId
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
