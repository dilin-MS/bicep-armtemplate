
module __azureSqlDeploy__ '__azureSqlFilePath__' = {
  name: 'azureSqlDeploy'
  params: {
    sqlServerName: azureSql_serverName
    sqlDatabaseName: azureSql_databaseName
    AADUser: AADUser
    AADObjectId: AADObjectId
    AADTenantId: tenantId
    administratorLogin: azureSql_adminLogin
    administratorLoginPassword: azureSql_adminLoginPassword
  }
}
