param simpleAuthWebAPPName string
param oauthAuthorityHost string = environment().authentication.loginEndpoint
param tenantId string
param aadMetadataAddress string = uri(oauthAuthorityHost, '${tenantId}/v2.0/.well-known/openid-configuration')
param allowedAadIds string = '1fec8e78-bce4-4aaf-ab1b-5451cc387264;5e3ce6c0-2b1f-4285-8d4b-75ee78787346'
param AADClientId string
@secure()
param AADClientSecret string
param applicationIdUri string

param frontendHostingStorageEndpoint string

var oauthAuthority = uri(oauthAuthorityHost, tenantId)

resource simpleAuthWebAppSettings 'Microsoft.Web/sites/config@2018-02-01' = {
  name: '${simpleAuthWebAPPName}/appsettings'
  properties: {
    AAD_METADATA_ADDRESS: aadMetadataAddress
    ALLOWED_APP_IDS: allowedAadIds
    IDENTIFIER_URI: applicationIdUri
    CLIENT_ID: AADClientId
    CLIENT_SECRET: AADClientSecret
    OAUTH_AUTHORITY: oauthAuthority
    TAB_APP_ENDPOINT: frontendHostingStorageEndpoint
  }  
}
