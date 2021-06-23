param functionPrefix string
param AADClientId string
param functionServerfarmsName string = '${functionPrefix}-function-serverfarms'
param functionAppName string = '${functionPrefix}-functionapp'
param oauthAuthorityHost string = environment().authentication.loginEndpoint
param tenantId string

var oauthAuthority = uri(oauthAuthorityHost, tenantId)

param functionAppSiteConfigsFromOtherModules object
param functionAppAuthAllowedAudiences array
param functionAppAllowedOrigins array

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
        allowedOrigins: functionAppAllowedOrigins
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
  properties: union(functionAppSiteConfigsFromOtherModules, {
    API_ENDPOINT: functionApp.properties.hostNames[0]
    WEBSITE_NODE_DEFAULT_VERSION: '~12'
    WEBSITE_RUN_FROM_PACKAGE: '1'
    WEBSITE_CONTENTSHARE: functionApp.name
    FUNCTIONS_EXTENSION_VERSION: '~3'
    FUNCTIONS_WORKER_RUNTIME: 'node'
    M365_AUTHORITY_HOST: oauthAuthorityHost
  })
}

resource functionAppAuthSettings 'Microsoft.Web/sites/config@2018-02-01' = {
  parent: functionApp
  name: 'authsettings'
  properties: {
    enabled: true
    defaultProvider: 'AzureActiveDirectory'
    clientId: AADClientId
    issuer: '${oauthAuthority}/v2.0'
    allowedAudiences: functionAppAuthAllowedAudiences
  }
}

output functionAppName string = functionApp.name
output appServicePlanName string = functionServerfarms.name
output functionEndpoint string = 'https://${functionApp.properties.hostNames[0]}'
