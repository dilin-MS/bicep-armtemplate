param simpleAuthPrefix string
param sku string = 'B1'
param simpleAuthServerFarmsName string = '${simpleAuthPrefix}-simple-auth-serverfarms'
param simpleAuthWebAppName string = '${simpleAuthPrefix}-simple-auth-webapp'
param tenantId string = '72f988bf-86f1-41af-91ab-2d7cd011db47'
param oauthAuthorityHost string = environment().authentication.loginEndpoint
param aadMetadataAddress string = uri(oauthAuthorityHost, '${tenantId}/v2.0/.well-known/openid-configuration')
param allowedAadIds string = '1fec8e78-bce4-4aaf-ab1b-5451cc387264;5e3ce6c0-2b1f-4285-8d4b-75ee78787346'
param AADClientId string
@secure()
param AADClientSecret string

param frontendHostingStorageEndpoint string
param applicationIdUri string

var oauthAuthority = uri(oauthAuthorityHost, tenantId)

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
