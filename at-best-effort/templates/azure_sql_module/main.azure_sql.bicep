param AADUser string
param AADObjectId string
param sqlAdminLogin string
@secure()
param sqlAdminLoginPassword string

module azureSqlDeploy 'azure_sql.bicep' = {
  name: 'azureSqlDeploy'
  scope: myResourceGroup
  params: {
    sqlPrefix: namePrefix
    AADUser: AADUser
    AADObjectId: AADObjectId
    AADTenantId: tenantId
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminLoginPassword
  }
}



output azureSqlConfig object = {
  sqlEndpoint: azureSqlDeploy.outputs.sqlEndpoint
  databaseName: azureSqlDeploy.outputs.databaseName
}
