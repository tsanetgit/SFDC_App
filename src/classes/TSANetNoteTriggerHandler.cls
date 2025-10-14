public class TSANetNoteTriggerHandler implements ITriggerHandler {
    public void beforeInsert(List<SObject> newItems) {
        tsanet_connect__TSANetNote__c[] notes = (tsanet_connect__TSANetNote__c[]) newItems;
        TSANetNoteTriggerHelper.findRelationships(notes);
    }
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {}
    public void beforeDelete(Map<Id, SObject> oldItems){}
    public void afterInsert(Map<Id, SObject> newItems){
        Map<Id, tsanet_connect__TSANetNote__c> notes = (Map<Id, tsanet_connect__TSANetNote__c>) newItems;
        TSANetNoteTriggerHelper.createFeedItems(notes.values());
    }
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        Map<Id, tsanet_connect__TSANetNote__c> notes = (Map<Id, tsanet_connect__TSANetNote__c>) newItems;
        Map<Id, tsanet_connect__TSANetNote__c> oldNotes = (Map<Id, tsanet_connect__TSANetNote__c>) oldItems;
        
        TSANetNoteTriggerHelper.createFeedItems(notes.values());

    }
    public void afterDelete(Map<Id, SObject> oldItems){}
    public void afterUndelete(Map<Id, SObject> newItems){}
    public Boolean isDisabled(){
        return false;
    }
}