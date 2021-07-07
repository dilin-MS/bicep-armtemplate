
module __functionDeploy__ '__functionFilePath__' = {
  name: 'functionDeploy'
  params: {
    functionAppName: function_webappName
    functionServerfarmsName: function_serverfarmsName
    functionStorageName: function_storageName
    AADClientId: AADClientId
    AADClientSecret: AADClientSecret
    tenantId: tenantId
    applicationIdUri: applicationIdUri
    {{#contains 'frontend_hosting' pluginTypes}}
    frontendHostingStorageEndpoint: __frontendHostingDeploy__.outputs.endpoint
    {{/contains}}
    {{#contains 'azure_sql' pluginTypes}}
    sqlDatabaseName: __azureSqlDeploy__.outputs.databaseName
    sqlEndpoint: __azureSqlDeploy__.outputs.sqlEndpoint
    {{/contains}}
    {{#contains 'identity' pluginTypes}}
    identityId: __identityDeploy__.outputs.identityId
    {{/contains}}
  }
}
