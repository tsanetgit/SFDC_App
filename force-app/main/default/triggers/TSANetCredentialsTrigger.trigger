trigger TSANetCredentialsTrigger on tsanetconnect__TSANet_Credentials__c (before insert, after insert, before update, before delete) {
    if (Trigger.isBefore) {
        if(Trigger.isInsert) {
            TSANetCredentialsHelper.turnOfPrimaryTSANetCredentials((tsanetconnect__TSANet_Credentials__c[]) Trigger.new);
        }
        
        if(Trigger.isUpdate) {
            TSANetCredentialsHelper.turnOfPrimaryTSANetCredentialsOnUpdate((tsanetconnect__TSANet_Credentials__c[]) Trigger.new, 
                                                                           (Map<Id, tsanetconnect__TSANet_Credentials__c>) Trigger.oldMap);
            TSANetCredentialsHelper.changePrimaryUser((tsanetconnect__TSANet_Credentials__c[]) Trigger.new, 
                                                      (Map<Id, tsanetconnect__TSANet_Credentials__c>) Trigger.oldMap);
        }
        
        if(Trigger.isDelete) {
            TSANetCredentialsHelper.checkPrimaryTSANetCredentialsOnDelete((tsanetconnect__TSANet_Credentials__c[]) Trigger.old);
        }
    }
    if (Trigger.isAfter) {
        if(Trigger.isInsert) {
            TSANetCredentialsHelper.getToken((tsanetconnect__TSANet_Credentials__c[]) Trigger.new);
        }
    }
}