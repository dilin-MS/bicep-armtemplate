param frontendHostingStorageEndpoint string
param functionPrefix string
@minLength(36)
@maxLength(36)
param AADClientId string
@minLength(34)
@maxLength(34)
param AADClientSecret string
param applicationIdUri string
param functionStorageName string

@minLength(2)
@description('Name of App Service Plan for function backend.')
param functionServerfarmsName string = '${functionPrefix}-function-serverfarms'

@minLength(2)
@description('Function app name.')
param functionAppName string = '${functionPrefix}-functionapp'

@description('Microsoft oauth authority host')
param oauthAuthorityHost string = environment().authentication.loginEndpoint

@description('Tenant id.')
param tenantId string = '72f988bf-86f1-41af-91ab-2d7cd011db47'

@description('Allowed AAD ids.')
param allowedAadIds string = '1fec8e78-bce4-4aaf-ab1b-5451cc387264;5e3ce6c0-2b1f-4285-8d4b-75ee78787346'

var oauthAuthority = '${oauthAuthorityHost}/${tenantId}'

resource functionServerfarms 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: functionServerfarmsName
  location: resourceGroup().location
  sku: {
    name: 'Y1'
  }
  kind: 'functionapp'
  properties: {
    reserved: false
  }
}

resource functionApp 'Microsoft.Web/sites@2020-06-01' = {
  kind: 'functionapp'
  name: functionAppName
  location: resourceGroup().location
  properties: {
    reserved: false
    serverFarmId: functionServerfarms.id
    siteConfig: {
      cors: {
        allowedOrigins: [
          frontendHostingStorageEndpoint
        ]
      }
      alwaysOn: false
      http20Enabled: false
      numberOfWorkers: 1
    }
  }
}

resource functionAppAppSettings 'Microsoft.Web/sites/config@2018-02-01' = {
  parent: functionApp
  name: 'appsettings'
  properties: {
    API_ENDPOINT: functionApp.properties.hostNames[0]
    ALLOWED_APP_IDS: allowedAadIds
    AzureWebJobsDashboard: 'DefaultEndpointsProtocol=https;AccountName=${functionStorageName};AccountKey=${listKeys(resourceId(resourceGroup().name, 'Microsoft.Storage/storageAccounts', functionStorageName), '2019-04-01').keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
    AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${functionStorageName};AccountKey=${listKeys(resourceId(resourceGroup().name, 'Microsoft.Storage/storageAccounts', functionStorageName), '2019-04-01').keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: 'DefaultEndpointsProtocol=https;AccountName=${functionStorageName};AccountKey=${listKeys(resourceId(resourceGroup().name, 'Microsoft.Storage/storageAccounts', functionStorageName), '2019-04-01').keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
    WEBSITE_NODE_DEFAULT_VERSION: '~12'
    WEBSITE_RUN_FROM_PACKAGE: '1'
    WEBSITE_CONTENTSHARE: functionApp.name
    FUNCTIONS_EXTENSION_VERSION: '~3'
    FUNCTIONS_WORKER_RUNTIME: 'node'
    M365_APPLICATION_ID_URI: applicationIdUri
    M365_CLIENT_ID: AADClientId
    M365_CLIENT_SECRET: AADClientSecret
    M365_TENANT_ID: tenantId
    M365_AUTHORITY_HOST: oauthAuthorityHost
  }  
}

resource functionAppAuthSettings 'Microsoft.Web/sites/config@2018-02-01' = {
  parent: functionApp
  name: 'authsettings'
  properties: {
    enabled: true
    defaultProvider: 'AzureActiveDirectory'
    clientId: AADClientId
    issuer: '${oauthAuthority}/v2.0'
    allowedAudiences: [
      AADClientId
      applicationIdUri
    ]
  }
}

output functionAppName string = functionApp.name
output appServicePlanName string = functionServerfarms.name
output functionEndpoint string = 'https://${functionApp.properties.hostNames[0]}'
