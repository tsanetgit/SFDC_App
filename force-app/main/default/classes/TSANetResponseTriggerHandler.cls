/** Trigger handler for TSANetResponse__c records. */
public inherited sharing class TSANetResponseTriggerHandler implements ITriggerHandler {
    /**
     * Links incoming responses to their parent TSANet cases before insert.
     * @param newItems new TSANetResponse__c records
     */
    public void beforeInsert(List<SObject> newItems) {
        tsanetconnect__TSANetResponse__c[] responses = (tsanetconnect__TSANetResponse__c[]) newItems;
        TSANetResponseTriggerHelper.findRelationships(responses);

    }
    /**
     * Handles before-update logic for TSANetResponse__c records.
     * @param newItems new versions of updated records
     * @param oldItems previous versions of updated records
     */
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        // Not implemented
    }
    /**
     * Handles before-delete logic for TSANetResponse__c records.
     * @param oldItems records being deleted
     */
    public void beforeDelete(Map<Id, SObject> oldItems){
        // Not implemented
    }
    /**
     * Copies engineer info from responses to parent TSANet cases after insert.
     * @param newItems newly inserted TSANetResponse__c records
     */
    public void afterInsert(Map<Id, SObject> newItems){
        Map<Id, tsanetconnect__TSANetResponse__c> responses = (Map<Id, tsanetconnect__TSANetResponse__c>) newItems;
        TSANetResponseTriggerHelper.assignEngineerInfo(responses.values());
    }
    /**
     * Handles after-update logic for TSANetResponse__c records.
     * @param newItems new versions of updated records
     * @param oldItems previous versions of updated records
     */
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        // Not implemented
    }
    /**
     * Handles after-delete logic for TSANetResponse__c records.
     * @param oldItems records that were deleted
     */
    public void afterDelete(Map<Id, SObject> oldItems){
        // Not implemented
    }
    /**
     * Handles after-undelete logic for TSANetResponse__c records.
     * @param newItems records that were undeleted
     */
    public void afterUndelete(Map<Id, SObject> newItems){
        // Not implemented
    }
    /**
     * Indicates whether this trigger handler is disabled.
     * @return always false; handler is always active
     */
    public Boolean isDisabled(){
        return false;
    }
}