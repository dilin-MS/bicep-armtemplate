targetScope = 'subscription'
param namePrefix string
param location string = deployment().location
param AADClientId string
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

output frontendHosting_storageName string = frontendHostingStorageDeploy.outputs.storageName
output frontendHosting_endpoint string = frontendHostingStorageDeploy.outputs.endpoint
output frontendHosting_domain string = frontendHostingStorageDeploy.outputs.domain

output simpleAuth_skuName string = simpleAuthWebAppDeploy.outputs.skuName
output simpleAuth_endpoint string = simpleAuthWebAppDeploy.outputs.endpoint
