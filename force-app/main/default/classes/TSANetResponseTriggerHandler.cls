public class TSANetResponseTriggerHandler implements ITriggerHandler {
    public void beforeInsert(List<SObject> newItems) {
        tsanetconnect__TSANetResponse__c[] responses = (tsanetconnect__TSANetResponse__c[]) newItems;
        TSANetResponseTriggerHelper.findRelationships(responses);
        
    }
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {}
    public void beforeDelete(Map<Id, SObject> oldItems){}
    public void afterInsert(Map<Id, SObject> newItems){
        Map<Id, tsanetconnect__TSANetResponse__c> responses = (Map<Id, tsanetconnect__TSANetResponse__c>) newItems;
        TSANetResponseTriggerHelper.assignEngineerInfo(responses.values());
    }
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        Map<Id, tsanetconnect__TSANetResponse__c> responses = (Map<Id, tsanetconnect__TSANetResponse__c>) newItems;
        Map<Id, tsanetconnect__TSANetResponse__c> oldResponses = (Map<Id, tsanetconnect__TSANetResponse__c>) oldItems;
        

    }
    public void afterDelete(Map<Id, SObject> oldItems){}
    public void afterUndelete(Map<Id, SObject> newItems){}
    public Boolean isDisabled(){
        return false;
    }
}