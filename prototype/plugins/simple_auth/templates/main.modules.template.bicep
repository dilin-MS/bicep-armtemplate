
module simpleAuthDeploy 'simple_auth.bicep' = {
  name: 'simpleAuthWebAppDeploy'
  params: {
    simpleAuthServerFarmsName: simpleAuth_serverFarmsName
    simpleAuthWebAppName: simpleAuth_webAppName
    sku: simpleAuth_sku
    AADClientId: AADClientId
    AADClientSecret: AADClientSecret
    applicationIdUri: applicationIdUri
    {{#each pluginTypes}}
    {{#if_equal this 'frontend_hosting'}}
    frontendHostingStorageEndpoint: __frontendHostingDeploy__.outputs.endpoint
    {{/if_equal}}
    {{/each}}
    tenantId: tenantId
  }
}
