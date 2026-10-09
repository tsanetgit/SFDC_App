/** Trigger handler for TSANetNote__c records. */
public with sharing class TSANetNoteTriggerHandler implements ITriggerHandler {
    /** Finds relationships for new notes and suppresses notifications for historical ones before insert.
     * @param newItems new note records being inserted
     */
    public void beforeInsert(List<SObject> newItems) {
        tsanetconnect__TSANetNote__c[] notes = (tsanetconnect__TSANetNote__c[]) newItems;
        TSANetNoteTriggerHelper.findRelationships(notes);
        TSANetNoteTriggerHelper.markStaleNotesAsNotified(notes);
    }
    /**
     * Self-heals notes whose parent TSANetCase__c lookup is still missing.
     * Required because webhook upserts hit beforeUpdate (not beforeInsert) when the note
     * already exists from an earlier sync, so any previously unlinked rows would otherwise
     * stay broken forever. Also marks historical notes as notified, because a sync upsert
     * of pre-existing rows lands here rather than in beforeInsert.
     * @param newItems updated note records
     * @param oldItems previous versions of the records
     */
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        tsanetconnect__TSANetNote__c[] notes = (tsanetconnect__TSANetNote__c[]) newItems.values();
        List<tsanetconnect__TSANetNote__c> needsLink = new List<tsanetconnect__TSANetNote__c>();
        for (tsanetconnect__TSANetNote__c note : notes) {
            if (String.isNotBlank(note.tsanetconnect__CaseId__c)) {
                needsLink.add(note);
            }
        }
        if (!needsLink.isEmpty()) {
            TSANetNoteTriggerHelper.findRelationships(needsLink);
        }
        TSANetNoteTriggerHelper.markStaleNotesAsNotified(notes);
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
    /** Not implemented — no post-update logic required.
     * @param newItems updated note records (post-save state)
     * @param oldItems previous versions of the records (pre-save state)
     */
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        // Not implemented
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