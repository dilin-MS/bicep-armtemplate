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
param AADClientSecret string

resource myResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${namePrefix}-rg'
  location: location
}

module frontendHostingStorage 'frontend_hosting_storage.bicep' = {
  name: 'frontendHostingStorageDeploy'
  scope: myResourceGroup
  params: {
     storagePrefix: namePrefix
  }
}

var applicationIdUri = 'api://${frontendHostingStorage.outputs.domain}/${AADClientId}'
module simpleAuthWebApp 'simple_auth_webapp.bicep' = {
  name: 'simpleAuthWebAppDeploy'
  scope: myResourceGroup
  params: {
    simpleAuthPrefix: namePrefix
    applicationIdUri: applicationIdUri
    frontendHostingStorageEndpoint: frontendHostingStorage.outputs.endpoint
    AADClientId: AADClientId
    AADClientSecret: AADClientSecret
  }
  dependsOn: [
    frontendHostingStorage
  ]
}

module functionStorage 'function_storage.bicep' = {
  name: 'functionStorageDeploy'
  scope: myResourceGroup
  params: {
    storagePrefix: namePrefix
  }
}

module functionApp 'function_app.bicep' = {
  name: 'functionAppDeploy'
  scope: myResourceGroup
  params: {
    functionPrefix: namePrefix
    functionStorageName: functionStorage.outputs.storageAccountName
    AADClientId: AADClientId
    AADClientSecret: AADClientSecret
    applicationIdUri: applicationIdUri
    frontendHostingStorageEndpoint: frontendHostingStorage.outputs.endpoint
  }
  dependsOn: [
    functionStorage
    frontendHostingStorage
  ]
}

output frontendHostingConfig object = {
  storageName: frontendHostingStorage.outputs.storageName
  endpoint: frontendHostingStorage.outputs.endpoint
  domain: frontendHostingStorage.outputs.domain
}

output simpleAuthConfig object = {
  skuName: simpleAuthWebApp.outputs.skuName
  endpoint: simpleAuthWebApp.outputs.endpoint
}

output functionConfig object = {
  functionAppName: functionApp.outputs.functionAppName
  storageAccountName: functionStorage.outputs.storageAccountName
  appServicePlanName: functionApp.outputs.appServicePlanName
  functionEndpoint: functionApp.outputs.functionEndpoint
}
