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
param aadMetadataAddress string = '${oauthAuthorityHost}/${tenantId}/v2.0/.well-known/openid-configuration'

@description('Allowed AAD ids.')
param allowedAadIds string = '1fec8e78-bce4-4aaf-ab1b-5451cc387264;5e3ce6c0-2b1f-4285-8d4b-75ee78787346'

@minLength(36)
@maxLength(36)
@description('Client id of AAD app.')
param AADClientId string

@minLength(34)
@maxLength(34)
@description('Client secret of AAD app.')
param AADClientSecret string

param frontendHostingStorageEndpoint string
param applicationIdUri string
var oauthAuthority = '${oauthAuthorityHost}/${tenantId}'

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
      appSettings: [
        {
          name: 'AAD_METADATA_ADDRESS'
          value: aadMetadataAddress
        }
        {
          name: 'ALLOWED_APP_IDS'
          value: allowedAadIds
        }
        {
          name: 'CLIENT_ID'
          value: AADClientId
        }
        {
          name: 'CLIENT_SECRET'
          value: AADClientSecret
        }
        {
          name: 'OAUTH_AUTHORITY'
          value: oauthAuthority
        }
        {
          name: 'TAB_APP_ENDPOINT'
          value: frontendHostingStorageEndpoint
        }
        {
          name: 'IDENTIFIER_URI'
          value: applicationIdUri
        }
      ]
    }
  }
}

output skuName string = sku
output endpoint string = 'https://${simpleAuthWebApp.properties.hostNames[0]}'
