
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
