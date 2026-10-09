/** Manages TSANet configuration and credential updates. */
public with sharing class ConfigManager {

    /**
     * Refreshes the company name and Id on the primary credential from the TSANet API.
     * Uses the Named Credential, so no login call or token handling is involved.
     * @return true if the credentials were updated successfully
     */
    @AuraEnabled
    public static Boolean updateTSANetCredentials(){
        tsanetconnect__TSANet_Credentials__c credential = CredentialManager.getCredentials();

        if(!AuthModeManager.usesNamedCredential(credential)){
            throw new AuraHandledException(TSANetConstants.NOT_CONFIGURED_ERROR);
        }

        TSANetCompanyInfo info = TSANetAPIService.getCompanyInformation();
        if(info == null || info.company == null){
            return false;
        }

        if(!Schema.sObjectType.tsanetconnect__TSANet_Credentials__c.isUpdateable()
            || !Schema.sObjectType.tsanetconnect__TSANet_Credentials__c.fields.tsanetconnect__CompanyName__c.isUpdateable()
            || !Schema.sObjectType.tsanetconnect__TSANet_Credentials__c.fields.tsanetconnect__CompanyId__c.isUpdateable()){
            return false;
        }

        tsanetconnect__TSANet_Credentials__c updatedCredential = new tsanetconnect__TSANet_Credentials__c(
            Id = credential.Id,
            tsanetconnect__CompanyName__c = info.company.name,
            tsanetconnect__CompanyId__c = info.company.id
        );
        return Database.update(updatedCredential, AccessLevel.USER_MODE).isSuccess();
    }
}
