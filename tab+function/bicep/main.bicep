targetScope = 'subscription'

@minLength(3)
@maxLength(16)
param namePrefix string = 'dilintest'

param location string = deployment().location

// Pass in AAD App information
@minLength(36)
@maxLength(36)
param AADClientId string

@minLength(34)
@maxLength(34)
@secure()
param AADClientSecret string

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
module simpleAuthWebAppDeploy 'simple_auth_webapp.bicep' = {
  name: 'simpleAuthWebAppDeploy'
  scope: myResourceGroup
  params: {
    simpleAuthPrefix: namePrefix
    applicationIdUri: applicationIdUri
    frontendHostingStorageEndpoint: frontendHostingStorageDeploy.outputs.endpoint
    AADClientId: AADClientId
    AADClientSecret: AADClientSecret
  }
}

module functionStorageDeploy 'function_storage.bicep' = {
  name: 'functionStorageDeploy'
  scope: myResourceGroup
  params: {
    storagePrefix: namePrefix
  }
}

module functionAppDeploy 'function_app.bicep' = {
  name: 'functionAppDeploy'
  scope: myResourceGroup
  params: {
    functionPrefix: namePrefix
    functionStorageName: functionStorageDeploy.outputs.storageAccountName
    AADClientId: AADClientId
    AADClientSecret: AADClientSecret
    applicationIdUri: applicationIdUri
    frontendHostingStorageEndpoint: frontendHostingStorageDeploy.outputs.endpoint
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
