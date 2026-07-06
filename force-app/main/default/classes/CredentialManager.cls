/** Manages retrieval and updates of TSANet credential records. */
public with sharing class CredentialManager {

    /** Exception thrown when credentials are missing or invalid. */
    public class CredentialManagerException extends Exception {}

    /**
     * Returns the primary TSANet credentials record.
     * @return the active TSANet_Credentials__c record
     */
    public static tsanetconnect__TSANet_Credentials__c getCredentials(){
        tsanetconnect__TSANet_Credentials__c[] credentials = [SELECT Id, tsanetconnect__UserName__c, tsanetconnect__Password__c, tsanetconnect__Environment__c, tsanetconnect__isPrimary__c, tsanetconnect__IntegrationUser__c, tsanetconnect__CompanyId__c, tsanetconnect__CompanyName__c
                                                              FROM tsanetconnect__TSANet_Credentials__c
                                                              WHERE tsanetconnect__isPrimary__c = TRUE WITH USER_MODE];

        if(!credentials.isEmpty()){
            return credentials[0];
        } else {
            throw new CredentialManagerException('Username and password can not be empty!');
        }
    }

    /**
     * Returns a primary TSANet credentials record by its Id.
     * @param credentialId the credential record Id
     * @return the matching TSANet_Credentials__c record
     */
    public static tsanetconnect__TSANet_Credentials__c getCredentialById(Id credentialId){
        tsanetconnect__TSANet_Credentials__c[] credentials = [SELECT Id, tsanetconnect__UserName__c, tsanetconnect__Password__c, tsanetconnect__Environment__c, tsanetconnect__isPrimary__c, tsanetconnect__IntegrationUser__c, tsanetconnect__CompanyId__c, tsanetconnect__CompanyName__c
                                                               FROM tsanetconnect__TSANet_Credentials__c
                                                               WHERE Id =:credentialId AND tsanetconnect__isPrimary__c = TRUE WITH USER_MODE];

        if(!credentials.isEmpty()){
            return credentials[0];
        } else {
            throw new CredentialManagerException('Username and password can not be empty!');
        }
    }

    /**
     * Returns the primary TSANet credentials record in system mode.
     * @return the active TSANet_Credentials__c record
     */
    public static tsanetconnect__TSANet_Credentials__c getCredentialsSystemMode(){
        tsanetconnect__TSANet_Credentials__c[] credentials = [SELECT Id, tsanetconnect__UserName__c, tsanetconnect__Password__c, tsanetconnect__Environment__c, tsanetconnect__isPrimary__c, tsanetconnect__IntegrationUser__c, tsanetconnect__CompanyId__c, tsanetconnect__CompanyName__c
                                                              FROM tsanetconnect__TSANet_Credentials__c
                                                              WHERE tsanetconnect__isPrimary__c = TRUE WITH SYSTEM_MODE];

        if(!credentials.isEmpty()){
            return credentials[0];
        } else {
            throw new CredentialManagerException('Username and password can not be empty!');
        }
    }

    /**
     * Updates stored credentials with company information from TSANet.
     * @param info the company info to persist
     */
    public static void updateCredentials(TSANetCompanyInfo info){
        tsanetconnect__TSANet_Credentials__c credential = getCredentials();
        credential.tsanetconnect__CompanyName__c = info.company.name;
        credential.tsanetconnect__CompanyId__c = info.company.id;
        Database.update(credential, AccessLevel.USER_MODE).isSuccess();
    }
}
