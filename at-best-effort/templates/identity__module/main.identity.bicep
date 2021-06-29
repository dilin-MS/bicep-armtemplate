
module identityDeploy 'identity.bicep' = {
  name: 'identityDeploy'
  scope: myResourceGroup
  params: {
     namePrefix: namePrefix
  }
}


output identityConfig object = {
  identityName: identityDeploy.outputs.identityName
  identityId: identityDeploy.outputs.identityId
  identity: identityDeploy.outputs.identity
}
