targetScope = 'subscription'
param namePrefix string
param location string = deployment().location
param tenantId string

// input params
{{#each pluginTypes}}
{{#if_equal this 'aad_app'}}
param AADClientId string
@secure()
param AADClientSecret string
{{/if_equal}}
{{#if_equal this 'simple_auth'}}
param simpleAuthWebAppSKU string
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
resource myResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${namePrefix}-rg'
  location: location
}

{{#each pluginTypes}}
{{#if_equal this 'frontend_hosting'}}
module frontendHostingDeploy 'frontend_hosting.bicep' = {
  name: 'frontendHostingDeploy'
  scope: myResourceGroup
}

{{/if_equal}}
{{#if_equal this 'simple_auth'}}
module simpleAuthDeploy 'simple_auth.bicep' = {
  name: 'simpleAuthWebAppDeploy'
  scope: myResourceGroup
  params: {
    simpleAuthPrefix: namePrefix
    sku: simpleAuthWebAppSKU
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
  scope: myResourceGroup
  params: {
    functionPrefix: namePrefix
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
  scope: myResourceGroup
  params: {
    sqlPrefix: namePrefix
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
  scope: myResourceGroup
  params: {
     namePrefix: namePrefix
  }
}

{{/if_equal}}
{{/each}}

// output
{{#each pluginTypes}}
{{#if_equal this 'frontend_hosting'}}
output frontendHosting_storageName string = frontendHostingDeploy.outputs.storageName
output frontendHosting_endpoint string = frontendHostingDeploy.outputs.endpoint
output frontendHosting_domain string = frontendHostingDeploy.outputs.domain

{{/if_equal}}
{{#if_equal this 'simple_auth'}}
output simpleAuth_skuName string = simpleAuthDeploy.outputs.skuName
output simpleAuth_endpoint string = simpleAuthDeploy.outputs.endpoint

{{/if_equal}}
{{#if_equal this 'function'}}
output functionConfig_storageAccountName string = functionDeploy.outputs.storageAccountName
output functionConfig_appServicePlanName string = functionDeploy.outputs.appServicePlanName
output functionConfig_functionEndpoint string = functionDeploy.outputs.functionEndpoint

{{/if_equal}}
{{#if_equal this 'azure_sql'}}
output azureSqlConfig_sqlEndpoint string =  azureSqlDeploy.outputs.sqlEndpoint
output azureSqlConfig_databaseName string =  azureSqlDeploy.outputs.databaseName

{{/if_equal}}
{{#if_equal this 'identity'}}
output identityConfig_identityName string =  identityDeploy.outputs.identityName
output identityConfig_identityId string =  identityDeploy.outputs.identityId
output identityConfig_identity string =  identityDeploy.outputs.identity

{{/if_equal}}
{{/each}}
