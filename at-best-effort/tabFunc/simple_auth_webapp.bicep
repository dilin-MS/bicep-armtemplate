param simpleAuthPrefix string

@description('The SKU of App Service Plan for frontend hosting.')
param sku string = 'B1'

@minLength(2)
@description('Name of App Service Plan for frontend hosting.')
param simpleAuthServerFarmsName string = '${simpleAuthPrefix}-simple-auth-serverfarms'

@minLength(2)
@description('Simple auth web app name.')
param simpleAuthWebAppName string = '${simpleAuthPrefix}-simple-auth-webapp'

@description('Tenant id.')
param tenantId string = '72f988bf-86f1-41af-91ab-2d7cd011db47'

@description('Microsoft oauth authority host')
param oauthAuthorityHost string = environment().authentication.loginEndpoint

@description('AAD metadata address.')
param aadMetadataAddress string = uri(oauthAuthorityHost, '${tenantId}/v2.0/.well-known/openid-configuration')

var oauthAuthority = uri(oauthAuthorityHost, tenantId)


param appSettingFromOtherModules object


resource simpleAuthServerFarms 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: simpleAuthServerFarmsName
  location: resourceGroup().location
  sku: {
    name: sku
  }
  kind: 'app'
  properties: {
    reserved: false
  }
}


resource simpleAuthWebApp 'Microsoft.Web/sites@2020-06-01' = {
  kind: 'app'
  name: simpleAuthWebAppName
  location: resourceGroup().location
  properties: {
    reserved: false
    serverFarmId: simpleAuthServerFarms.id
    siteConfig: {
      alwaysOn: false
      http20Enabled: false
      numberOfWorkers: 1
    }
  }
}

resource simpleAuthSiteConfig 'Microsoft.Web/sites/config@2021-01-01' = {
  parent: simpleAuthWebApp
  name: 'appsettings'
  properties: union(appSettingFromOtherModules, {
    AAD_METADATA_ADDRESS: aadMetadataAddress
    OAUTH_AUTHORITY: oauthAuthority
  })
}

output skuName string = sku
output endpoint string = 'https://${simpleAuthWebApp.properties.hostNames[0]}'
