/**
 * Trigger handler for the TSANetNoteFeedItemRequested__e Platform Event.
 * FeedItems are inserted from the TSANetNote trigger as the end user or External
 * Client App Run As user. This subscriber is a no-op so Automated Process
 * does not perform SOQL or DML. The PE object is kept for managed-package safety.
 */
public with sharing class TSANetNoteFeedItemRequestedHandler implements ITriggerHandler {

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
     * No-op. Note trigger creates FeedItems in USER_MODE.
     * @param newItems map of newly published Platform Event records by replay Id
     */
    public void afterInsert(Map<Id, SObject> newItems){
        // Guest PE hop removed. Keep the handler so the packaged trigger still compiles.
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
}
