/** Contract that all trigger handler implementations must fulfill. */
public interface ITriggerHandler {
    /**
     * Executes logic before new records are inserted.
     * @param newItems list of new records being inserted
     */
    void beforeInsert(List<SObject> newItems);
    /**
     * Executes logic before existing records are updated.
     * @param newItems map of updated records by Id
     * @param oldItems map of old record versions by Id
     */
    void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems);
    /**
     * Executes logic before records are deleted.
     * @param oldItems map of records being deleted by Id
     */
    void beforeDelete(Map<Id, SObject> oldItems);
    /**
     * Executes logic after new records are inserted.
     * @param newItems map of newly inserted records by Id
     */
    void afterInsert(Map<Id, SObject> newItems);
    /**
     * Executes logic after existing records are updated.
     * @param newItems map of updated records by Id
     * @param oldItems map of old record versions by Id
     */
    void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems);
    /**
     * Executes logic after records are deleted.
     * @param oldItems map of deleted records by Id
     */
    void afterDelete(Map<Id, SObject> oldItems);
    /**
     * Executes logic after records are undeleted.
     * @param oldItems map of undeleted records by Id
     */
    void afterUndelete(Map<Id, SObject> oldItems);
    /**
     * Indicates whether this trigger handler is currently disabled.
     * @return true if the handler should be skipped
     */
    Boolean isDisabled();
}