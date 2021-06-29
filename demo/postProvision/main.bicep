targetScope = 'subscription'
param resourceGroupName string
param AADClientId string
@secure()
param AADClientSecret string
param tenantId string

param frontendHostingStorageEndpoint string
param simpleAuthWebAPPName string
param identityId string
param sqlDatabaseName string
param sqlEndpoint string
param functionStorageName string
param functionAppEndpoint string
param functionAppName string

var applicationIdUri = 'api://${frontendHostingStorageEndpoint}/${AADClientId}'

resource myResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' existing = {
  name: resourceGroupName
}

module simpleAuthConfigDeploy 'simple_auth_postconfig.bicep' = {
  name: 'simpleAuthConfigDeploy'
  scope: myResourceGroup
  params: {
    applicationIdUri: applicationIdUri
    frontendHostingStorageEndpoint: frontendHostingStorageEndpoint
    AADClientId: AADClientId
    AADClientSecret: AADClientSecret
    simpleAuthWebAPPName: simpleAuthWebAPPName
    tenantId: tenantId
  }
}

module functionConfigDeploy 'function_postconfig.bicep' = {
  name: 'functionConfigDeploy'
  scope: myResourceGroup
  params: {
    AADClientId: AADClientId
    AADClientSecret: AADClientSecret
    tenantId: tenantId
    applicationIdUri: applicationIdUri
    frontendHostingStorageEndpoint: frontendHostingStorageEndpoint
    identityId: identityId
    sqlDatabaseName: sqlDatabaseName
    sqlEndpoint: sqlEndpoint
    functionStorageName: functionStorageName
    functionAppEndpoint: functionAppEndpoint
    functionAppName: functionAppName
  }
}
