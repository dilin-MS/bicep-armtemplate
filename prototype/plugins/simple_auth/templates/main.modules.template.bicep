
module __simpleAuthDeploy__ '__simpleAuthFilePath__' = {
  name: 'simpleAuthWebAppDeploy'
  params: {
    simpleAuthServerFarmsName: simpleAuth_serverFarmsName
    simpleAuthWebAppName: simpleAuth_webAppName
    sku: simpleAuth_sku
    AADClientId: AADClientId
    AADClientSecret: AADClientSecret
    applicationIdUri: applicationIdUri
    {{#contains 'frontend_hosting' pluginTypes}}
    frontendHostingStorageEndpoint: __frontendHostingDeploy__.outputs.endpoint
    {{/contains}}
    tenantId: tenantId
  }
}
