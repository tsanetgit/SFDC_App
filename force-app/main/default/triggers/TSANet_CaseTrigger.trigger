trigger TSANet_CaseTrigger on tsanetconnect__TSANetCase__c (before insert) {

    // Parent-Case linking logic has been moved to the
    // "TSANet: Inbound: Find Parent Case" record-triggered flow.
    // This trigger is intentionally left inert.

    /*
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            tsanetconnect__TSANetCase__c[] cases = (tsanetconnect__TSANetCase__c[]) Trigger.new;
            TSANetCaseTriggerHandler.handleBeforeInsert(cases);
        }
    }
    */

}
