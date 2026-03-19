public with sharing class TSANetCredentialsHelper {
    
    public static void getToken(tsanetconnect__TSANet_Credentials__c[] credentials){
        for(tsanetconnect__TSANet_Credentials__c credential : credentials){
            if(credential.tsanetconnect__isPrimary__c == true){
                if(!Test.isRunningTest()){
                    InternalProcessManager.execute(credential);
                }
            }
        }
    }

    public static void turnOfPrimaryTSANetCredentials(tsanetconnect__TSANet_Credentials__c[] newCredentials){
        Boolean isPrimary = false;
        for(tsanetconnect__TSANet_Credentials__c newCredential : newCredentials){
            if(newCredential.tsanetconnect__isPrimary__c == true){
                isPrimary = true;
                if(newCredential.IntegrationUser__c == NULL){
                    newCredential.IntegrationUser__c = UserInfo.getUserId();
                }
            }
        }
        
        if(isPrimary == TRUE){
            tsanetconnect__TSANet_Credentials__c[] credentials = [SELECT Id, Name, tsanetconnect__UserName__c, tsanetconnect__Password__c, tsanetconnect__Environment__c, tsanetconnect__isPrimary__c FROM tsanetconnect__TSANet_Credentials__c WITH SECURITY_ENFORCED ];
            tsanetconnect__TSANet_Credentials__c[] credentialsToUpdate = new tsanetconnect__TSANet_Credentials__c[]{};
            for(tsanetconnect__TSANet_Credentials__c credential : credentials){
                if(credential.Id != NULL){
                    credential.tsanetconnect__isPrimary__c = false;
                    credentialsToUpdate.add(credential);
                }
            }
            Database.update(credentialsToUpdate, AccessLevel.USER_MODE);
        }
    }
    
    public static void turnOfPrimaryTSANetCredentialsOnUpdate(tsanetconnect__TSANet_Credentials__c[] newCredentials, Map<Id, tsanetconnect__TSANet_Credentials__c> oldCredentials){
        Boolean isPrimary = false;
        Id[] credentialIds = new Id[]{};
        for(tsanetconnect__TSANet_Credentials__c newCredential : newCredentials){
            if(newCredential.tsanetconnect__isPrimary__c == true && 
               ( oldCredentials.get(newCredential.Id).tsanetconnect__isPrimary__c != newCredential.tsanetconnect__isPrimary__c )){
               	
                isPrimary = true;
               	if(!Test.isRunningTest()){
               		InternalProcessManager.execute(newCredential);
               	}
               	credentialIds.add(newCredential.Id);
            }
            
            if(newCredential.tsanetconnect__isPrimary__c == false && 
               ( oldCredentials.get(newCredential.Id).tsanetconnect__isPrimary__c != newCredential.tsanetconnect__isPrimary__c )){

            }
        }
        
        if(isPrimary == TRUE){
            tsanetconnect__TSANet_Credentials__c[] credentials = [SELECT Id, Name, tsanetconnect__UserName__c, tsanetconnect__Password__c, tsanetconnect__Environment__c, tsanetconnect__isPrimary__c FROM tsanetconnect__TSANet_Credentials__c WHERE Id NOT IN:credentialIds WITH SECURITY_ENFORCED ];
            for(tsanetconnect__TSANet_Credentials__c credential : credentials){
                credential.tsanetconnect__isPrimary__c = false;
            }
            Database.update(credentials, AccessLevel.USER_MODE);
        }
    }
    
    public static void changePrimaryUser(tsanetconnect__TSANet_Credentials__c[] newCredentials, Map<Id, tsanetconnect__TSANet_Credentials__c> oldCredentials){
		Id integrationUser;
        for(tsanetconnect__TSANet_Credentials__c newCredential : newCredentials){
            if(newCredential.tsanetconnect__IntegrationUser__c != NULL &&
               oldCredentials.get(newCredential.Id).tsanetconnect__IntegrationUser__c != newCredential.tsanetconnect__IntegrationUser__c ){
               integrationUser = newCredential.tsanetconnect__IntegrationUser__c;
            }
        }
    }
    
    public static void checkPrimaryTSANetCredentialsOnDelete(tsanetconnect__TSANet_Credentials__c[] credentials){
        for(tsanetconnect__TSANet_Credentials__c credential : credentials){
            if(credential.tsanetconnect__isPrimary__c == TRUE){
                credential.addError('You can’t remove primary credentials. Please mark them as non-primary and try again!');
            } else {
                InternalProcessManager.abortTSANetJobs(credential.Id);
            }
        }
    }
}