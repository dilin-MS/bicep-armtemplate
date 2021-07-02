@minLength(3)
@maxLength(24)
@description('Name of Storage Accounts for frontend hosting.')
param frontend_hosting_storage_name string

resource frontendHostingStorage 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  kind: 'StorageV2'
  location: resourceGroup().location
  name: frontend_hosting_storage_name
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    isHnsEnabled: false
  }
  sku: {
    name: 'Standard_LRS'
  }
}

output connectionString string = 'DefaultEndpointsProtocol=https;AccountName=${frontendHostingStorage.name};AccountKey=${listKeys(resourceId(resourceGroup().name, 'Microsoft.Storage/storageAccounts', frontendHostingStorage.name), '2019-04-01').keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
output storageName string = frontendHostingStorage.name
output endpoint string = frontendHostingStorage.properties.primaryEndpoints.web
output domain string = replace(replace(frontendHostingStorage.properties.primaryEndpoints.web, 'https://', ''), '/', '')
