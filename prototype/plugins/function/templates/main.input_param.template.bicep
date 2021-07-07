
param function_serverfarmsName string = '${resourceGroupName}-function-serverfarms'
param function_webappName string = '${resourceGroupName}-function-webapp'
@minLength(3)
@maxLength(24)
@description('Name of Storage Accounts for function backend.')
param function_storageName string = 'functionstg${uniqueString(resourceGroupName)}'
