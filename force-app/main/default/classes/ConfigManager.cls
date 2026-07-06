/** Manages TSANet configuration and credential updates. */
public with sharing class ConfigManager {

    /**
     * Fetches a new access token and company info, then updates stored credentials.
     * @return true if the credentials were updated successfully
     */
    @AuraEnabled
    public static Boolean updateTSANetCredentials(){

        AuthManager.AccessTokenResponse loginResponse = TSANetService.login();
        if (loginResponse == null || String.isBlank(loginResponse.accessToken)) {
            return false;
        }

        String token = loginResponse.accessToken;
        TSANetCompanyInfo info = TSANetService.getCompanyInformation(token);

        tsanetconnect__TSANet_Credentials__c credential = CredentialManager.getCredentials();
        credential.tsanetconnect__CompanyName__c = info.company.name;
        credential.tsanetconnect__CompanyId__c = info.company.id;
        TokenManager.updateToken(token, loginResponse.expiresIn);
        return Database.update(credential, AccessLevel.USER_MODE).isSuccess();
    }
}
