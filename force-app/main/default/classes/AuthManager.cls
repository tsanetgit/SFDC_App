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
     * Retrieves the stored access token, refreshing when missing or expired.
     * @return concatenated access token string
     */
    public static String getAccessToken(){
        try {
            return TokenManager.getAccessToken();
        } catch (TokenManager.TokenManagerException e) {
            throw new AuthManagerException(e.getMessage());
        }
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
        AuthManager.AccessTokenResponse response = TSANetService.login();
        if(response == null || String.isBlank(response.accessToken)){ return false; }

        TokenManager.updateToken(response.accessToken, response.expiresIn);
        InternalProcessManager.execute(credential);
        return true;
    }
}
