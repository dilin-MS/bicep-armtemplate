var functionAppSiteConfigs = {
  ALLOWED_APP_IDS: allowedAadIds
  AzureWebJobsDashboard: functionStorageDeploy.outputs.storageConnectionString
  AzureWebJobsStorage: functionStorageDeploy.outputs.storageConnectionString
  WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: functionStorageDeploy.outputs.storageConnectionString
  M365_APPLICATION_ID_URI: applicationIdUri
  M365_CLIENT_ID: AADClientId
  M365_CLIENT_SECRET: AADClientSecret
  M365_TENANT_ID: tenantId  
  IDENTITY_ID: identityDeploy.outputs.identityId
  SQL_DATABASE_NAME: azureSqlDeploy.outputs.databaseName
  SQL_ENDPOINT: azureSqlDeploy.outputs.sqlEndpoint
}
var functionAppAuthAllowedAudiences = [
  AADClientId
  applicationIdUri
]
var functionAppAllowedOrigins = [
  frontendHostingStorageDeploy.outputs.endpoint
]

module functionAppDeploy 'function_app.bicep' = {
  name: 'functionAppDeploy'
  scope: myResourceGroup
  params: {
    functionPrefix: namePrefix
    AADClientId: AADClientId
    tenantId: tenantId
    functionAppSiteConfigsFromOtherModules: functionAppSiteConfigs
    functionAppAuthAllowedAudiences: functionAppAuthAllowedAudiences
    functionAppAllowedOrigins: functionAppAllowedOrigins
  }
}
