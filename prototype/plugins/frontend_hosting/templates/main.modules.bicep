
module frontendHostingDeploy 'frontend_hosting.bicep' = {
  name: 'frontendHostingDeploy'
  params: {
    frontend_hosting_storage_name: frontendHosting_storageName
  }
}
