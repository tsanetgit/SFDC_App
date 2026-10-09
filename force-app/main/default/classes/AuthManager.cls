/** Reconnects the TSANet integration by re-running the setup sync for the primary credential. */
public with sharing class AuthManager {

    /** Exception thrown for authentication failures. */
    public class AuthManagerException extends Exception {}

    /**
     * Re-runs the TSANet setup sync for the primary credential. Named Credential callouts are
     * authorized by the External Credential, so there is no token to refresh: the credential is
     * marked disconnected and the account probe decides whether it comes back connected.
     * @return true when the reconnect was started
     */
    @AuraEnabled
    public static Boolean updateAccessToken(){
        tsanetconnect__TSANet_Credentials__c credential = CredentialManager.getCredentials();

        if(!AuthModeManager.usesNamedCredential(credential)){
            throw new AuraHandledException(TSANetConstants.NOT_CONFIGURED_ERROR);
        }

        InternalProcessManager.markDisconnected(credential);
        InternalProcessManager.execute(credential);
        return true;
    }
}
