trigger TSANet_CaseTrigger on tsanetconnect__TSANetCase__c (before insert) {

    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            tsanetconnect__TSANetCase__c[] cases = (tsanetconnect__TSANetCase__c[]) Trigger.new;
            TSANetCaseTriggerHandler.handleBeforeInsert(cases);
        }
    }

}
