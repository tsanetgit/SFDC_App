/**
 * Trigger handler for the TSANetNoteFeedItemRequested__e Platform Event.
 * Runs as the Run-As User (Automated Process by default), which has Chatter access,
 * so it can perform the FeedItem insert that the original Site Guest User context cannot.
 */
public without sharing class TSANetNoteFeedItemRequestedHandler implements ITriggerHandler {

    public void beforeInsert(List<SObject> newItems){
        // Not implemented — Platform Events don't fire before-insert.
    }

    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        // Not implemented — Platform Events are insert-only.
    }

    public void beforeDelete(Map<Id, SObject> oldItems){
        // Not implemented — Platform Events are insert-only.
    }

    /**
     * Re-queries the requested notes in SYSTEM_MODE and delegates back to the
     * shared FeedItem-creation logic, which now runs in a non-Guest context.
     * @param newItems map of newly published Platform Event records by replay Id
     */
    public void afterInsert(Map<Id, SObject> newItems){
        Set<Id> noteIds = collectNoteIds(newItems.values());
        if (noteIds.isEmpty()) { return; }

        tsanetconnect__TSANetNote__c[] notes = TSANetNoteSelector.getForFeedItemBuild(noteIds);
        if (notes.isEmpty()) { return; }

        TSANetNoteTriggerHelper.createFeedItems(notes);
    }

    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        // Not implemented — Platform Events are insert-only.
    }

    public void afterDelete(Map<Id, SObject> oldItems){
        // Not implemented — Platform Events are insert-only.
    }

    public void afterUndelete(Map<Id, SObject> newItems){
        // Not implemented — Platform Events are insert-only.
    }

    /**
     * @return true if this handler is disabled
     */
    public Boolean isDisabled(){
        return false;
    }

    /** Extracts note Ids from the published events, ignoring blanks/duplicates. */
    private static Set<Id> collectNoteIds(List<SObject> events){
        Set<Id> ids = new Set<Id>();
        for (SObject evt : events){
            String raw = (String) evt.get('tsanetconnect__NoteId__c');
            if (String.isBlank(raw)) { continue; }
            try {
                ids.add((Id) raw);
            } catch (System.StringException e){
                ErrorLogger.logError(e, 'TSANET_NOTE_FEED_ITEM_PE_INVALID_ID');
            }
        }
        return ids;
    }
}
