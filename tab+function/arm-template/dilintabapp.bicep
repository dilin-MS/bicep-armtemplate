@description('Project name.')
param project_name string = 'dilintabapp0610'

@minLength(2)
@description('Web app name.')
param web_app_name string = '${project_name}webapp'

@minLength(2)
@description('Web app name.')
param function_app_name string = '${project_name}functionapp'

@minLength(2)
@description('Name of App Service Plan for tab frontend.')
param tab_serverfarms_name string = '${project_name}tab'

@minLength(3)
@maxLength(24)
@description('Name of Storage Accounts for tab frontend.')
param tab_storageAccounts_name string = '${project_name}tab'

@minLength(2)
@description('Name of App Service Plan for function backend.')
param function_serverfarms_name string = '${project_name}func'

@minLength(3)
@maxLength(24)
@description('Name of Storage Accounts for function backend.')
param function_storageAccounts_name string = '${project_name}func'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The SKU of App Service Plan for tab frontend.')
param appServicePlan_sku string = 'B1'

@description('aad metadata address.')
param aadMetadataAddress string = 'https://login.microsoftonline.com/72f988bf-86f1-41af-91ab-2d7cd011db47/v2.0/.well-known/openid-configuration'

@description('Allowed AAD ids.')
param allowedAadIds string = '1fec8e78-bce4-4aaf-ab1b-5451cc387264;5e3ce6c0-2b1f-4285-8d4b-75ee78787346'

@description('Client id of AAD app.')
param clientId string

@description('Client secret of AAD app.')
param clientSecret string

@description('Microsoft oauth authority host')
param oauthAuthorityHost string = 'https://login.microsoftonline.com'

@description('tenant id.')
param tenantId string = '72f988bf-86f1-41af-91ab-2d7cd011db47'

var tab_app_endpoint = 'https://${tab_storageAccounts_name}.z13.web.core.windows.net'
var application_id_uri = 'api://${tab_storageAccounts_name}.z13.web.core.windows.net/${clientId}'
var oauth_authority = '${oauthAuthorityHost}/${tenantId}'

resource tab_storageAccounts_name_resource 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  kind: 'StorageV2'
  location: location
  name: tab_storageAccounts_name
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    isHnsEnabled: false
  }
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
}

resource function_storageAccounts_name_resource 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  kind: 'StorageV2'
  location: location
  name: function_storageAccounts_name
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    isHnsEnabled: true
  }
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
}

resource tab_serverfarms_name_resource 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: tab_serverfarms_name
  location: location
  sku: {
    name: appServicePlan_sku
  }
  kind: 'app'
  properties: {
    reserved: false
  }
}

resource function_serverfarms_name_resource 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: function_serverfarms_name
  location: location
  sku: {
    name: 'Y1'
  }
  kind: 'functionapp'
  properties: {
    reserved: false
  }
}

resource web_app_name_resource 'Microsoft.Web/sites@2020-06-01' = {
  kind: 'app'
  name: web_app_name
  location: location
  properties: {
    reserved: false
    serverFarmId: tab_serverfarms_name_resource.id
    siteConfig: {
      alwaysOn: false
      http20Enabled: false
      numberOfWorkers: 1
      appSettings: [
        {
          name: 'aadMetadataAddress'
          value: aadMetadataAddress
        }
        {
          name: 'ALLOWED_APP_IDS'
          value: allowedAadIds
        }
        {
          name: 'CLIENT_ID'
          value: clientId
        }
        {
          name: 'CLIENT_SECRET'
          value: clientSecret
        }
        {
          name: 'oauthAuthority'
          value: oauth_authority
        }
        {
          name: 'TAB_APP_ENDPOINT'
          value: tab_app_endpoint
        }
        {
          name: 'IDENTIFIER_URI'
          value: application_id_uri
        }
      ]
    }
  }
}

resource function_app_name_resource 'Microsoft.Web/sites@2020-06-01' = {
  kind: 'functionapp'
  name: function_app_name
  location: location
  properties: {
    reserved: false
    serverFarmId: function_serverfarms_name_resource.id
    siteConfig: {
      cors: {
        allowedOrigins: [
          tab_app_endpoint
        ]
      }
      alwaysOn: false
      http20Enabled: false
      numberOfWorkers: 1
      appSettings: [
        {
          name: 'API_ENDPOINT'
          value: 'https://${function_app_name}.azurewebsites.net'
        }
        {
          name: 'ALLOWED_APP_IDS'
          value: allowedAadIds
        }
        {
          name: 'AzureWebJobsDashboard'
          value: 'DefaultEndpointsProtocol=https;AccountName=${function_storageAccounts_name};AccountKey=${listKeys(resourceId(project_name, 'Microsoft.Storage/storageAccounts', function_storageAccounts_name), '2019-04-01').keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${function_storageAccounts_name};AccountKey=${listKeys(resourceId(project_name, 'Microsoft.Storage/storageAccounts', function_storageAccounts_name), '2019-04-01').keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
        {
          name: 'M365_APPLICATION_ID_URI'
          value: application_id_uri
        }
        {
          name: 'M365_CLIENT_ID'
          value: clientId
        }
        {
          name: 'M365_CLIENT_SECRET'
          value: clientSecret
        }
        {
          name: 'M365_TENANT_ID'
          value: tenantId
        }
        {
          name: 'M365_AUTHORITY_HOST'
          value: oauthAuthorityHost
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${function_storageAccounts_name};AccountKey=${listKeys(resourceId(project_name, 'Microsoft.Storage/storageAccounts', function_storageAccounts_name), '2019-04-01').keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~12'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: function_app_name
        }
      ]
    }
  }
  dependsOn: [
    function_storageAccounts_name_resource
  ]
}

resource function_app_name_authsettings 'Microsoft.Web/sites/config@2018-02-01' = {
  parent: function_app_name_resource
  name: 'authsettings'
  properties: {
    enabled: true
    defaultProvider: 'AzureActiveDirectory'
    clientId: clientId
    issuer: '${oauth_authority}/v2.0'
    allowedAudiences: [
      clientId
      application_id_uri
    ]
  }
}

output tab_app_endpoint string = tab_app_endpoint
output storageAccountConnectionString string = 'DefaultEndpointsProtocol=https;AccountName=${function_storageAccounts_name};AccountKey=${listKeys(resourceId(project_name, 'Microsoft.Storage/storageAccounts', function_storageAccounts_name), '2019-04-01').keys[0].value};EndpointSuffix=core.windows.net'