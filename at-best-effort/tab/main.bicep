targetScope = 'subscription'
param namePrefix string
param location string = deployment().location
param AADClientId string
@secure()
param AADClientSecret string
param allowedAadIds string


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

output frontendHostingConfig object = {
  storageName: frontendHostingStorageDeploy.outputs.storageName
  endpoint: frontendHostingStorageDeploy.outputs.endpoint
  domain: frontendHostingStorageDeploy.outputs.domain
}

output simpleAuthConfig object = {
  skuName: simpleAuthWebAppDeploy.outputs.skuName
  endpoint: simpleAuthWebAppDeploy.outputs.endpoint
}
