param AADClientId string
@secure()
param AADClientSecret string
param oauthAuthorityHost string = environment().authentication.loginEndpoint
param tenantId string
param allowedAadIds string = '1fec8e78-bce4-4aaf-ab1b-5451cc387264;5e3ce6c0-2b1f-4285-8d4b-75ee78787346'

param applicationIdUri string
param identityId string
param sqlDatabaseName string
param sqlEndpoint string
param functionStorageName string
param functionAppEndpoint string
param functionAppName string
param frontendHostingStorageEndpoint string

var oauthAuthority = uri(oauthAuthorityHost, tenantId)

resource functionAppAppSettings 'Microsoft.Web/sites/config@2018-02-01' = {
  name: '${functionAppName}/appsettings'
  properties: {
    API_ENDPOINT: functionAppEndpoint
    ALLOWED_APP_IDS: allowedAadIds
    AzureWebJobsDashboard: 'DefaultEndpointsProtocol=https;AccountName=${functionStorageName};AccountKey=${listKeys(resourceId(resourceGroup().name, 'Microsoft.Storage/storageAccounts', functionStorageName), '2019-04-01').keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
    AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${functionStorageName};AccountKey=${listKeys(resourceId(resourceGroup().name, 'Microsoft.Storage/storageAccounts', functionStorageName), '2019-04-01').keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: 'DefaultEndpointsProtocol=https;AccountName=${functionStorageName};AccountKey=${listKeys(resourceId(resourceGroup().name, 'Microsoft.Storage/storageAccounts', functionStorageName), '2019-04-01').keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
    WEBSITE_NODE_DEFAULT_VERSION: '~12'
    WEBSITE_RUN_FROM_PACKAGE: '1'
    WEBSITE_CONTENTSHARE: functionAppName
    FUNCTIONS_EXTENSION_VERSION: '~3'
    FUNCTIONS_WORKER_RUNTIME: 'node'
    M365_APPLICATION_ID_URI: applicationIdUri
    M365_CLIENT_ID: AADClientId
    M365_CLIENT_SECRET: AADClientSecret
    M365_TENANT_ID: tenantId
    M365_AUTHORITY_HOST: oauthAuthorityHost
    IDENTITY_ID: identityId
    SQL_DATABASE_NAME: sqlDatabaseName
    SQL_ENDPOINT: sqlEndpoint
  }
}

resource functionAppAuthSettings 'Microsoft.Web/sites/config@2018-02-01' = {
  name: '${functionAppName}/authsettings'
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

resource functionAppSiteConfig 'Microsoft.Web/sites/config@2018-02-01' = {
  name: '${functionAppName}/web'
  properties: {    
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
