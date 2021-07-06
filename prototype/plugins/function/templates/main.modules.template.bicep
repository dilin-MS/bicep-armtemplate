
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
  }
}
