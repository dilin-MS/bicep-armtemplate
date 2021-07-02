targetScope = 'resourceGroup'
param resourceGroupName string
param tenantId string

// input params
param AADClientId string
@secure()
param AADClientSecret string
@minLength(3)
@maxLength(24)
@description('Name of Storage Accounts for frontend hosting.')
param frontendHosting_storageName string = 'frontendstg${uniqueString(resourceGroupName)}'
param function_serverfarmsName string = '${resourceGroupName}-function-serverfarms'
param function_webappName string = '${resourceGroupName}-function-webapp'
@minLength(3)
@maxLength(24)
@description('Name of Storage Accounts for function backend.')
param function_storageName string = 'functionstg${uniqueString(resourceGroupName)}'
param simpleAuth_sku string
param simpleAuth_serverFarmsName string = '${resourceGroupName}-simpleAuth-serverfarms'
param simpleAuth_webAppName string = '${resourceGroupName}-simpleAuth-webapp'

// variables
var applicationIdUri = 'api://${frontendHostingDeploy.outputs.domain}/${AADClientId}'

// resources and modules
module frontendHostingDeploy 'frontend_hosting.bicep' = {
  name: 'frontendHostingDeploy'
  params: {
    frontend_hosting_storage_name: frontendHosting_storageName
  }
}

module functionDeploy 'function.bicep' = {
  name: 'functionDeploy'
  params: {
    functionAppName: function_webappName
    functionServerfarmsName: function_serverfarmsName
    functionStorageName: function_storageName
    AADClientId: AADClientId
    AADClientSecret: AADClientSecret
    tenantId: tenantId
    applicationIdUri: applicationIdUri
    frontendHostingStorageEndpoint: frontendHostingDeploy.outputs.endpoint
  }
}

module simpleAuthDeploy 'simple_auth.bicep' = {
  name: 'simpleAuthWebAppDeploy'
  params: {
    simpleAuthServerFarmsName: simpleAuth_serverFarmsName
    simpleAuthWebAppName: simpleAuth_webAppName
    sku: simpleAuth_sku
    AADClientId: AADClientId
    AADClientSecret: AADClientSecret
    applicationIdUri: applicationIdUri
    frontendHostingStorageEndpoint: frontendHostingDeploy.outputs.endpoint
    tenantId: tenantId
  }
}


// output
output frontendHosting_connectionString string = frontendHostingDeploy.outputs.connectionString
output frontendHosting_storageName string = frontendHostingDeploy.outputs.storageName
output frontendHosting_endpoint string = frontendHostingDeploy.outputs.endpoint
output frontendHosting_domain string = frontendHostingDeploy.outputs.domain

output function_storageAccountName string = functionDeploy.outputs.storageAccountName
output function_appServicePlanName string = functionDeploy.outputs.appServicePlanName
output function_functionEndpoint string = functionDeploy.outputs.functionEndpoint

output simpleAuth_skuName string = simpleAuthDeploy.outputs.skuName
output simpleAuth_endpoint string = simpleAuthDeploy.outputs.endpoint

