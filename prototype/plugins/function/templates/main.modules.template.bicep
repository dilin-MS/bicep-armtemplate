
module functionDeploy 'function.bicep' = {
  name: 'functionDeploy'
  params: {
    functionAppName: function_webappName
    functionServerfarmsName: function_serverfarmsName
    functionStorageName: function_storageName
    AADClientId: AADClientId
    AADClientSecret: AADClientSecret
    tenantId: tenantId
    applicationIdUri: applicationIdUri
    {{#each pluginTypes}}
    {{#if_equal this 'frontend_hosting'}}
    frontendHostingStorageEndpoint: __frontendHostingDeploy__.outputs.endpoint
    {{/if_equal}}
    {{/each}}
    
  }
}
