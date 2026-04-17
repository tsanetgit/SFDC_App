declare module "@salesforce/apex/CredentialManager.getCredentials" {
  export default function getCredentials(): Promise<any>;
}
declare module "@salesforce/apex/CredentialManager.getCredentialById" {
  export default function getCredentialById(param: {credentialId: any}): Promise<any>;
}
