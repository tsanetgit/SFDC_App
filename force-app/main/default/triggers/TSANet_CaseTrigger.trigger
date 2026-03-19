trigger TSANet_CaseTrigger on tsanetconnect__TSANetCase__c (before insert, after update) {
    
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            tsanetconnect__TSANetCase__c[] cases = (tsanetconnect__TSANetCase__c[]) Trigger.new;
            TSANetCaseTriggerHandler.handleBeforeInsert(cases);
        }
    }
    
	if (Trigger.isAfter) {
        if (Trigger.isUpdate) {
            tsanetconnect__TSANetCase__c[] cases = (tsanetconnect__TSANetCase__c[]) Trigger.new;
        	Map<Id, tsanetconnect__TSANetCase__c> oldCases = (Map<Id, tsanetconnect__TSANetCase__c>) Trigger.oldMap;
            
            TSANetCaseTriggerHandler.handleAfterUpdate(cases, oldCases);
        }
    }
   
}