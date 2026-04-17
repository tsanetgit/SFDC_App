/** Trigger handler for TSANetNote__c records. */
public inherited sharing class TSANetNoteTriggerHandler implements ITriggerHandler {
    /** Finds relationships for new notes before insert.
     * @param newItems new note records being inserted
     */
    public void beforeInsert(List<SObject> newItems) {
        tsanetconnect__TSANetNote__c[] notes = (tsanetconnect__TSANetNote__c[]) newItems;
        TSANetNoteTriggerHelper.findRelationships(notes);
    }
    /** Not implemented — no pre-update logic required.
     * @param newItems updated note records
     * @param oldItems previous versions of the records
     */
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        // Not implemented
    }
    /** Not implemented — no pre-delete logic required.
     * @param oldItems note records being deleted
     */
    public void beforeDelete(Map<Id, SObject> oldItems){
        // Not implemented
    }
    /** Creates case feed items after note records are inserted.
     * @param newItems newly inserted note records
     */
    public void afterInsert(Map<Id, SObject> newItems){
        Map<Id, tsanetconnect__TSANetNote__c> notes = (Map<Id, tsanetconnect__TSANetNote__c>) newItems;
        TSANetNoteTriggerHelper.createFeedItems(notes.values());
    }
    /** Creates case feed items after note records are updated.
     * @param newItems updated note records
     * @param oldItems previous versions of the records
     */
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        Map<Id, tsanetconnect__TSANetNote__c> notes = (Map<Id, tsanetconnect__TSANetNote__c>) newItems;

        TSANetNoteTriggerHelper.createFeedItems(notes.values());

    }
    /** Not implemented — no post-delete logic required.
     * @param oldItems deleted note records
     */
    public void afterDelete(Map<Id, SObject> oldItems){
        // Not implemented
    }
    /** Not implemented — no post-undelete logic required.
     * @param newItems undeleted note records
     */
    public void afterUndelete(Map<Id, SObject> newItems){
        // Not implemented
    }
    /**
     * Indicates whether this trigger handler is disabled.
     * @return true if the handler is disabled
     */
    public Boolean isDisabled(){
        return false;
    }
}