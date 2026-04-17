trigger TSANetResponseTrigger on tsanetconnect__TSANetResponse__c (before insert, after insert) {

    TriggerDispatcher.run(new TSANetResponseTriggerHandler());

}