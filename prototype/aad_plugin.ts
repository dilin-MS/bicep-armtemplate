export interface AADInfo {
    clientId: string;
    clientSecret: string;
  }
  
/**
 * AAD plugin create app registration and return information of the AAD app.
 */
export function createAADApp(): AADInfo {
    // hard-code here
    return {
        clientId: '40beaf37-3903-494d-92b8-3ecbf5d68546',
        clientSecret: 'xxx'
    }
}

export function calculateApplicationIdUri(domain: string, clientId: string): string {
    return `api://${domain}/${clientId}`;
}