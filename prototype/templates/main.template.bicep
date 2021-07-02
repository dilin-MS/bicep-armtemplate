targetScope = 'resourceGroup'
param resourceGroupName string
param tenantId string

// input params
{{#each pluginTypes}}
{{#if_equal this 'aad_app'}}
param AADClientId string
@secure()
param AADClientSecret string
{{/if_equal}}
{{#if_equal this 'frontend_hosting'}}
@minLength(3)
@maxLength(24)
@description('Name of Storage Accounts for frontend hosting.')
param frontendHosting_storageName string = 'frontendstg${uniqueString(resourceGroupName)}'
{{/if_equal}}
{{#if_equal this 'function'}}
param function_serverfarmsName string = '${resourceGroupName}-function-serverfarms'
param function_webappName string = '${resourceGroupName}-function-webapp'
@minLength(3)
@maxLength(24)
@description('Name of Storage Accounts for function backend.')
param function_storageName string = 'functionstg${uniqueString(resourceGroupName)}'
{{/if_equal}}
{{#if_equal this 'simple_auth'}}
param simpleAuth_sku string
param simpleAuth_serverFarmsName string = '${resourceGroupName}-simpleAuth-serverfarms'
param simpleAuth_webAppName string = '${resourceGroupName}-simpleAuth-webapp'
{{/if_equal}}
{{#if_equal this 'azure_sql'}}
param AADUser string
param AADObjectId string
param sqlAdminLogin string
param sqlAdminLoginPassword string
{{/if_equal}}
{{/each}}

// variables
{{#each pluginTypes}}
{{#if_equal this 'aad_app'}}
{{#ifIn 'frontend_hosting' ../pluginTypes}}
{{#ifNotIn 'bot' ../pluginTypes}}
var applicationIdUri = 'api://${frontendHostingDeploy.outputs.domain}/${AADClientId}'
{{/ifNotIn}}
{{#ifIn 'bot' ../pluginTypes}}
var applicationIdUri = 'api://${frontendHostingDeploy.outputs.domain}/botid-${AADClientId}'
{{/ifIn}}
{{/ifIn}}
{{#ifNotIn 'frontend_hosting' ../pluginTypes}}
{{#ifIn 'bot' ../pluginTypes}}
var applicationIdUri = 'api://${botDeploy.outputs.domain}/botid-${AADClientId}'
{{/ifIn}}
{{/ifNotIn}}
{{/if_equal}}
{{/each}}

// resources and modules
{{#each pluginTypes}}
{{#if_equal this 'frontend_hosting'}}
module frontendHostingDeploy 'frontend_hosting.bicep' = {
  name: 'frontendHostingDeploy'
  params: {
    frontend_hosting_storage_name: frontendHosting_storageName
  }
}

{{/if_equal}}
{{#if_equal this 'simple_auth'}}
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

{{/if_equal}}
{{#if_equal this 'function'}}
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

{{/if_equal}}
{{#if_equal this 'azure_sql'}}
module azureSqlDeploy 'azure_sql.bicep' = {
  name: 'azureSqlDeploy'
  params: {
    sqlresourceGroupName: nameresourceGroupName
    AADUser: AADUser
    AADObjectId: AADObjectId
    AADTenantId: tenantId
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminLoginPassword
  }
}

{{/if_equal}}
{{#if_equal this 'identity'}}
module identityDeploy 'identity.bicep' = {
  name: 'identityDeploy'
  params: {
     nameresourceGroupName: nameresourceGroupName
  }
}

{{/if_equal}}
{{/each}}

// output
{{#each pluginTypes}}
{{#if_equal this 'frontend_hosting'}}
output frontendHosting_connectionString string = frontendHostingDeploy.outputs.connectionString
output frontendHosting_storageName string = frontendHostingDeploy.outputs.storageName
output frontendHosting_endpoint string = frontendHostingDeploy.outputs.endpoint
output frontendHosting_domain string = frontendHostingDeploy.outputs.domain

{{/if_equal}}
{{#if_equal this 'simple_auth'}}
output simpleAuth_skuName string = simpleAuthDeploy.outputs.skuName
output simpleAuth_endpoint string = simpleAuthDeploy.outputs.endpoint

{{/if_equal}}
{{#if_equal this 'function'}}
output function_storageAccountName string = functionDeploy.outputs.storageAccountName
output function_appServicePlanName string = functionDeploy.outputs.appServicePlanName
output function_functionEndpoint string = functionDeploy.outputs.functionEndpoint

{{/if_equal}}
{{#if_equal this 'azure_sql'}}
output azureSql_sqlEndpoint string =  azureSqlDeploy.outputs.sqlEndpoint
output azureSql_databaseName string =  azureSqlDeploy.outputs.databaseName

{{/if_equal}}
{{#if_equal this 'identity'}}
output identity_identityName string =  identityDeploy.outputs.identityName
output identity_identityId string =  identityDeploy.outputs.identityId
output identity_identity string =  identityDeploy.outputs.identity

{{/if_equal}}
{{/each}}
