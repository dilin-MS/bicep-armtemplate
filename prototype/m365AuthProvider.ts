import { AuthenticationProvider } from "@microsoft/microsoft-graph-client";
import {
  AccessToken,
  TokenCredential,
  GetTokenOptions,
  ClientSecretCredential,
  TokenCredentialOptions,
  AuthenticationError,
  UsernamePasswordCredential
} from "@azure/identity";

class M365AuthProvider implements AuthenticationProvider {
  private readonly credential: UsernamePasswordCredential;
  constructor(tenantId: string, clientId: string, userName: string, password: string) {
    this.credential = new UsernamePasswordCredential(tenantId, clientId, userName, password);
  }

  public async getAccessToken(): Promise<string> {
      this.credential.getToken()
  }
}
