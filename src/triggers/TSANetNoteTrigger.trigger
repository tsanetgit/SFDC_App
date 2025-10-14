trigger TSANetNoteTrigger on tsanet_connect__TSANetNote__c (before insert, after insert, 
                                            before update, after update, 
                                            before delete, after delete, after undelete) { 
                                                
	TriggerDispatcher.run(new TSANetNoteTriggerHandler());
}