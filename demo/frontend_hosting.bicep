// This template deploys an Azure Storage account, and then configures it to support static website hosting.
// Enabling static website hosting isn't possible directly in Bicep or an ARM template,
// so this file uses a deployment script to enable the feature.

param storagePrefix string

@minLength(3)
@maxLength(24)
@description('Name of Storage Accounts for frontend hosting.')
param frontend_hosting_storage_name string = '${substring(toLower(storagePrefix), 0, 13)}frontendstg'

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

output storageName string = frontendHostingStorage.name
// output endpoint string = frontendHostingStorage.properties.primaryEndpoints.web
// output domain string = replace(replace(frontendHostingStorage.properties.primaryEndpoints.web, 'https://', ''), '/', '')
