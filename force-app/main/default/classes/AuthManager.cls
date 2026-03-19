public with sharing class AuthManager {
    
    public class AuthManagerException extends Exception {}
    
    public static  tsanetconnect__TSANet_Credentials__c credential = CredentialManager.getCredentials();
    
    public class AccessTokenResponse {
        public String accessToken;
        public String tokenType;
        public Integer expiresIn;
    }
    
    
    @AuraEnabled
    public static String getAccessToken(){
        if(credential.tsanetconnect__AccessTokenPart1__c == NULL || credential.tsanetconnect__AccessTokenPart2__c == NULL){
            throw new AuthManagerException('Unauthorized');
        }
        return credential.tsanetconnect__AccessTokenPart1__c + credential.tsanetconnect__AccessTokenPart2__c;
    }
    
    public static String getBearerToken(){
        String token = getAccessToken();
        if(token == NULL && !Test.isRunningTest()){
			throw new AuthManagerException('Unauthorized');
        }
        return 'Bearer ' + token;
    }

    @AuraEnabled
    public static Boolean updateAccessToken(){
        
        String token = TSANetService.getTSANetAccessToken();
        if(token == NULL){ return false; }
        
        InternalProcessManager.execute(credential);
        return Database.update(new tsanetconnect__TSANet_Credentials__c(Id = credential.Id, 
                                                                         tsanetconnect__Token__c = token), AccessLevel.USER_MODE).isSuccess();
    }
}