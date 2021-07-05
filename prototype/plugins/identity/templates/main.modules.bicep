
module identityDeploy 'identity.bicep' = {
  name: 'identityDeploy'
  params: {
    managedIdentityName: managedIdentityName
  }
}
