trigger TSANetResponseTrigger on tsanet_connect__TSANetResponse__c (before insert, after insert, 
                                                      before update, after update, 
                                                      before delete, after delete, after undelete) { 
                                                          
    TriggerDispatcher.run(new TSANetResponseTriggerHandler());

}