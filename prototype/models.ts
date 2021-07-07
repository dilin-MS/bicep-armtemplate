export enum PluginTypes {
  AAD = "aad",
  Function = "function",
  FrontendHosting = "frontend_hosting",
  AzureSql = "azure_sql",
  Identity = "identity",
  SimpleAuth = "simple_auth",
}

export interface PluginBicepSnippet {
    PluginTypes: PluginTypes,
    PluginResources?: string,
    MainInputParams?: string,
    MainVars?: string,
    MainModules?: string,
    MainOutput?: string
    Parameter?: object,
  }