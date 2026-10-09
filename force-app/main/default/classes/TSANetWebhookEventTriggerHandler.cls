/**
 * Platform Event subscriber for inbound TSANet webhooks.
 * Processing and typing-indicator notify run as the External Client App user
 * in TSANetWebhookRestService. This trigger must not perform SOQL or DML
 * because High Volume PE Apex runs as Automated Process.
 */
public with sharing class TSANetWebhookEventTriggerHandler implements ITriggerHandler {

    public void beforeInsert(List<SObject> newItems){
        // Platform Events do not fire before-insert.
    }

    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        // Platform Events are insert-only.
    }

    public void beforeDelete(Map<Id, SObject> oldItems){
        // Platform Events are insert-only.
    }

    /**
     * No-op. REST already notifies the UI and enqueues the queueable as the Integration User.
     * @param newItems map of newly published Platform Event records by replay Id
     */
    public void afterInsert(Map<Id, SObject> newItems){
        handleEvents(newItems == null ? new List<SObject>() : newItems.values());
    }

    /**
     * Intentionally empty: Automated Process must not query or write subscriber data.
     * @param events inbound TSANetWebhookEvent__e records
     */
    public static void handleEvents(List<SObject> events){
        // REST owns notify + queueable. Keep this method so tests and any old callers stay safe.
    }

    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        // Platform Events are insert-only.
    }

    public void afterDelete(Map<Id, SObject> oldItems){
        // Platform Events are insert-only.
    }

    public void afterUndelete(Map<Id, SObject> newItems){
        // Platform Events are insert-only.
    }

    public Boolean isDisabled(){
        return false;
    }
}
