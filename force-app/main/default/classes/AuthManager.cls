/** Manages authentication and access token operations for TSANet API. */
public with sharing class AuthManager {

    /** Exception thrown for authentication failures. */
    public class AuthManagerException extends Exception {}

    /** Wrapper for the access token HTTP response payload. */
    public class AccessTokenResponse {
        /** The OAuth access token string. */
        public String accessToken;
        /** The token type (e.g. Bearer). */
        public String tokenType;
        /** Token lifetime in seconds. */
        public Integer expiresIn;
    }

    /**
     * Retrieves the stored access token from credentials.
     * @return concatenated access token string
     */
    public static String getAccessToken(){
        tsanetconnect__TSANet_Credentials__c credential = CredentialManager.getCredentials();
        if(credential.tsanetconnect__AccessTokenPart1__c == NULL || credential.tsanetconnect__AccessTokenPart2__c == NULL){
            throw new AuthManagerException('Unauthorized');
        }
        return credential.tsanetconnect__AccessTokenPart1__c + credential.tsanetconnect__AccessTokenPart2__c;
    }

    /**
     * Returns the access token prefixed with "Bearer ".
     * @return Bearer token string
     */
    public static String getBearerToken(){
        String token = getAccessToken();
        if(token == NULL && !Test.isRunningTest()){
			throw new AuthManagerException('Unauthorized');
        }
        return 'Bearer ' + token;
    }

    /**
     * Refreshes the stored access token from TSANet API.
     * @return true if the token was updated successfully
     */
    @AuraEnabled
    public static Boolean updateAccessToken(){
        tsanetconnect__TSANet_Credentials__c credential = CredentialManager.getCredentials();
        String token = TSANetService.getTSANetAccessToken();
        if(token == NULL){ return false; }

        InternalProcessManager.execute(credential);
        return Database.update(new tsanetconnect__TSANet_Credentials__c(Id = credential.Id,
                                                                         tsanetconnect__Token__c = token), AccessLevel.USER_MODE).isSuccess();
    }
}