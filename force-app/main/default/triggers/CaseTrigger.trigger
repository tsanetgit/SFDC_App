trigger CaseTrigger on Case  (after update) {
    
	if (Trigger.isAfter) {
        if (Trigger.isUpdate) {
            Case[] cases = (Case[]) Trigger.new;
        	Map<Id, Case> oldCases = (Map<Id, Case>) Trigger.oldMap;
            
            CaseTriggerHandler.handleAfterUpdate(cases, oldCases);
        }
    }
   
}