public with sharing class CredentialManager {
    
    public class CredentialManagerException extends Exception {}
    
	@AuraEnabled
    public static tsanetconnect__TSANet_Credentials__c getCredentials(){
        tsanetconnect__TSANet_Credentials__c[] credentials = [SELECT Id, tsanetconnect__UserName__c, tsanetconnect__Password__c, tsanetconnect__Environment__c, tsanetconnect__isPrimary__c, tsanetconnect__IntegrationUser__c, tsanetconnect__CompanyId__c, tsanetconnect__CompanyName__c, tsanetconnect__AccessTokenPart1__c, tsanetconnect__AccessTokenPart2__c 
                                                              FROM tsanetconnect__TSANet_Credentials__c 
                                                              WHERE tsanetconnect__isPrimary__c = TRUE WITH SECURITY_ENFORCED];
        
        if(!credentials.isEmpty()){
            return credentials[0];
        } else {
            throw new CredentialManagerException('Username and password can not be empty!');
        }
    }
    
    @AuraEnabled
    public static tsanetconnect__TSANet_Credentials__c getCredentialById(Id credentialId){
        tsanetconnect__TSANet_Credentials__c[] credentials = [SELECT Id, tsanetconnect__UserName__c, tsanetconnect__Password__c, tsanetconnect__Environment__c, tsanetconnect__isPrimary__c, tsanetconnect__IntegrationUser__c, tsanetconnect__CompanyId__c, tsanetconnect__CompanyName__c, tsanetconnect__AccessTokenPart1__c, tsanetconnect__AccessTokenPart2__c 
                                                               FROM tsanetconnect__TSANet_Credentials__c 
                                                               WHERE Id =:credentialId AND tsanetconnect__isPrimary__c = TRUE WITH SECURITY_ENFORCED];
        
        if(!credentials.isEmpty()){
            return credentials[0];
        } else {
            throw new CredentialManagerException('Username and password can not be empty!');
        }
    }
    
    public static void updateCredentials(TSANetCompanyInfo info){
        tsanetconnect__TSANet_Credentials__c credential = getCredentials();
        credential.tsanetconnect__CompanyName__c = info.company.name;
        credential.tsanetconnect__CompanyId__c = info.company.id;
        Database.update(credential, AccessLevel.USER_MODE).isSuccess();
    }
    
    public static void updateToken(String token){
        tsanetconnect__TSANet_Credentials__c credential = getCredentials();
        
        AccessTokenSplitter.SplitResult splitResult = AccessTokenSplitter.splitBy175(token);
        
        credential.tsanetconnect__AccessTokenPart1__c = splitResult.firstPart;
        credential.tsanetconnect__AccessTokenPart2__c = splitResult.restPart;
        Database.update(credential, AccessLevel.USER_MODE);
    }
}