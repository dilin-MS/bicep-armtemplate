
module azureSqlDeploy 'azure_sql.bicep' = {
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
