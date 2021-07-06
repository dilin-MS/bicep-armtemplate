
module __azureSqlDeploy__ '__azureSqlFilePath__' = {
  name: 'azureSqlDeploy'
  params: {
    sqlServerName: sqlServerName
    sqlDatabaseName: sqlDatabaseName
    AADUser: AADUser
    AADObjectId: AADObjectId
    AADTenantId: tenantId
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminLoginPassword
  }
}
