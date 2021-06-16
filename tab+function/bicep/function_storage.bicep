param storagePrefix string

@minLength(3)
@maxLength(24)
@description('Name of Storage Accounts for function backend.')
param functionStorageName string = '${storagePrefix}function'

resource functionStorage 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  kind: 'StorageV2'
  location: resourceGroup().location
  name: functionStorageName
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    isHnsEnabled: true
  }
  sku: {
    name: 'Standard_LRS'
  }
}

output storageAccountName string = functionStorage.name
