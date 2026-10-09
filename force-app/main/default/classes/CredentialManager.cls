/** Manages retrieval and updates of TSANet credential records. */
public with sharing class CredentialManager {

    /** Exception thrown when credentials are missing or invalid. */
    public class CredentialManagerException extends Exception {}

    private static final String NO_PRIMARY_RECORD_ERROR =
        'No primary TSANet Credentials record was found. Create one and mark it as primary.';

    /**
     * Returns the primary TSANet credentials record.
     * @return the active TSANet_Credentials__c record
     */
    public static tsanetconnect__TSANet_Credentials__c getCredentials(){
        tsanetconnect__TSANet_Credentials__c[] credentials = [SELECT Id, tsanetconnect__isPrimary__c, tsanetconnect__isConnected__c, tsanetconnect__CompanyId__c, tsanetconnect__CompanyName__c, tsanetconnect__NamedCredential__c, tsanetconnect__IntegrationUser__c
                                                              FROM tsanetconnect__TSANet_Credentials__c
                                                              WHERE tsanetconnect__isPrimary__c = TRUE WITH USER_MODE];

        if(!credentials.isEmpty()){
            return credentials[0];
        } else {
            throw new CredentialManagerException(NO_PRIMARY_RECORD_ERROR);
        }
    }

    /**
     * Returns a primary TSANet credentials record by its Id.
     * @param credentialId the credential record Id
     * @return the matching TSANet_Credentials__c record
     */
    public static tsanetconnect__TSANet_Credentials__c getCredentialById(Id credentialId){
        tsanetconnect__TSANet_Credentials__c[] credentials = [SELECT Id, tsanetconnect__isPrimary__c, tsanetconnect__isConnected__c, tsanetconnect__CompanyId__c, tsanetconnect__CompanyName__c, tsanetconnect__NamedCredential__c, tsanetconnect__IntegrationUser__c
                                                               FROM tsanetconnect__TSANet_Credentials__c
                                                               WHERE Id =:credentialId AND tsanetconnect__isPrimary__c = TRUE WITH USER_MODE];

        if(!credentials.isEmpty()){
            return credentials[0];
        } else {
            throw new CredentialManagerException(NO_PRIMARY_RECORD_ERROR);
        }
    }

    /**
     * True when the primary credential has a confirmed TSANet connection.
     * Missing credentials resolve to false so background jobs skip the callout.
     * @return true when the primary credential is connected
     */
    public static Boolean isConnected(){
        try {
            return getCredentials().tsanetconnect__isConnected__c == true;
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * Updates stored credentials with company information from TSANet.
     * @param info the company info to persist
     */
    public static void updateCredentials(TSANetCompanyInfo info){
        if(!Schema.sObjectType.tsanetconnect__TSANet_Credentials__c.isUpdateable()
            || !Schema.sObjectType.tsanetconnect__TSANet_Credentials__c.fields.tsanetconnect__CompanyName__c.isUpdateable()
            || !Schema.sObjectType.tsanetconnect__TSANet_Credentials__c.fields.tsanetconnect__CompanyId__c.isUpdateable()){
            return;
        }

        tsanetconnect__TSANet_Credentials__c credential = new tsanetconnect__TSANet_Credentials__c(
            Id = getCredentials().Id,
            tsanetconnect__CompanyName__c = info.company.name,
            tsanetconnect__CompanyId__c = info.company.id
        );
        Database.update(credential, AccessLevel.USER_MODE).isSuccess();
    }
}
