trigger TSANet_CaseTrigger on tsanet_connect__TSANetCase__c (before insert, after update) {
    
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            tsanet_connect__TSANetCase__c[] cases = (tsanet_connect__TSANetCase__c[]) Trigger.new;
            TSANetCaseTriggerHandler.handleBeforeInsert(cases);
        }
    }
    
	if (Trigger.isAfter) {
        if (Trigger.isUpdate) {
            tsanet_connect__TSANetCase__c[] cases = (tsanet_connect__TSANetCase__c[]) Trigger.new;
        	Map<Id, tsanet_connect__TSANetCase__c> oldCases = (Map<Id, tsanet_connect__TSANetCase__c>) Trigger.oldMap;
            
            TSANetCaseTriggerHandler.handleAfterUpdate(cases, oldCases);
        }
    }
   
}