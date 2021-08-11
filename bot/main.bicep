targetScope = 'resourceGroup'
param resourceBaseName string

// bot
param bot_aadClientId string
@secure()
param bot_aadClientSecret string
param bot_serviceName string = '${resourceBaseName}-bot-service'
param bot_serverfarmsName string = '${resourceBaseName}-bot-serverfarms'
param bot_webAppSKU string = 'F1'
param bot_serviceSKU string = 'F1'
param bot_sitesName string = '${resourceBaseName}-bot-sites'
param bot_displayName string = '${resourceBaseName}-bot-displayname'
param authLoginUriSuffix string = '/auth-start.html'
param m365ClientId string
@secure()
param m365ClientSecret string
param m365TenantId string
param m365OauthAuthorityHost string
param m365ApplicationIdUri string


module botProvision 'bot.bicep' = {
  name: 'botProvision'
  params: {
    botAadClientId: bot_aadClientId
    botAadClientSecret: bot_aadClientSecret
    botDisplayName: bot_displayName
    botServerfarmsName: bot_serverfarmsName
    botServiceName: bot_serviceName
    botServiceSKU: bot_serviceSKU
    botSitesName: bot_sitesName
    botWebAppSKU: bot_webAppSKU
    authLoginUriSuffix: authLoginUriSuffix
    m365ApplicationIdUri: m365ApplicationIdUri
    m365ClientId: m365ClientId
    m365ClientSecret: m365ClientSecret
    m365TenantId: m365TenantId
    m365OauthAuthorityHost: m365OauthAuthorityHost
  }
}
