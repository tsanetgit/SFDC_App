/** Manages TSANet credential lifecycle including token retrieval and primary flag toggling. */
public with sharing class TSANetCredentialsHelper {

    /**
     * Triggers token retrieval for each primary credential record.
     * @param credentials list of credential records to process
     */
    public static void getToken(tsanetconnect__TSANet_Credentials__c[] credentials){
        for(tsanetconnect__TSANet_Credentials__c credential : credentials){
            if(credential.tsanetconnect__isPrimary__c == true){
                if(!Test.isRunningTest()){
                    InternalProcessManager.execute(credential);
                }
            }
        }
    }

    /**
     * Deactivates existing primary credentials when a new primary is inserted.
     * @param newCredentials list of newly inserted credential records
     */
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
            tsanetconnect__TSANet_Credentials__c[] credentials = [SELECT Id, Name, tsanetconnect__UserName__c, tsanetconnect__Password__c, tsanetconnect__Environment__c, tsanetconnect__isPrimary__c FROM tsanetconnect__TSANet_Credentials__c WITH SECURITY_ENFORCED LIMIT 1000];
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

    /**
     * Deactivates other primary credentials when a credential is updated to primary.
     * @param newCredentials list of updated credential records
     * @param oldCredentials map of previous credential values by Id
     */
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

        }

        if(isPrimary == TRUE){
            tsanetconnect__TSANet_Credentials__c[] credentials = [SELECT Id, Name, tsanetconnect__UserName__c, tsanetconnect__Password__c, tsanetconnect__Environment__c, tsanetconnect__isPrimary__c FROM tsanetconnect__TSANet_Credentials__c WHERE Id NOT IN:credentialIds WITH SECURITY_ENFORCED ];
            for(tsanetconnect__TSANet_Credentials__c credential : credentials){
                credential.tsanetconnect__isPrimary__c = false;
            }
            Database.update(credentials, AccessLevel.USER_MODE);
        }
    }

    /**
     * Detects changes to the integration user on credential records.
     * @param newCredentials list of updated credential records
     * @param oldCredentials map of previous credential values by Id
     */
    public static void changePrimaryUser(tsanetconnect__TSANet_Credentials__c[] newCredentials, Map<Id, tsanetconnect__TSANet_Credentials__c> oldCredentials){
		Id integrationUser;
        for(tsanetconnect__TSANet_Credentials__c newCredential : newCredentials){
            if(newCredential.tsanetconnect__IntegrationUser__c != NULL &&
               oldCredentials.get(newCredential.Id).tsanetconnect__IntegrationUser__c != newCredential.tsanetconnect__IntegrationUser__c ){
               integrationUser = newCredential.tsanetconnect__IntegrationUser__c;
            }
        }
    }

    /**
     * Prevents deletion of primary credentials and aborts related jobs for non-primary ones.
     * @param credentials list of credential records being deleted
     */
    public static void checkPrimaryTSANetCredentialsOnDelete(tsanetconnect__TSANet_Credentials__c[] credentials){
        for(tsanetconnect__TSANet_Credentials__c credential : credentials){
            if(credential.tsanetconnect__isPrimary__c == TRUE){
                credential.addError('You can’t remove primary credentials. Please mark them as non-primary and try again!');
            } else {
                InternalProcessManager.abortTSANetJobs(credential.Id);
                //deleteChildWebhooks(credential.Id);
            }
        }
    }

    /** Deletes child TSANetWebhook__c records; the webhook trigger handles API-side deletion. */
    private static void deleteChildWebhooks(Id credentialId){
        String sfWebhookSuffix = '%/services/apexrest/tsanetconnect/webhook';
        tsanetconnect__TSANetWebhook__c[] webhooks = [
            SELECT Id FROM tsanetconnect__TSANetWebhook__c
            WHERE tsanetconnect__TSANetCredential__c = :credentialId
            AND tsanetconnect__CallbackUrl__c LIKE :sfWebhookSuffix
        ];
        if(!webhooks.isEmpty()){
            Database.delete(webhooks, false, AccessLevel.SYSTEM_MODE);
        }
    }
}