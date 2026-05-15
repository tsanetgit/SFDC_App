/** Centralized SOQL for tsanetconnect__TSANetNote__c. */
public inherited sharing class TSANetNoteSelector {

    /**
     * Lookup by token.
     * @param token unique note token to search for
     * @return matching TSANetNote__c record
     */
    public static tsanetconnect__TSANetNote__c getByToken(String token) {
        return [
            SELECT Id, Name, tsanetconnect__Token__c
            FROM tsanetconnect__TSANetNote__c
            WHERE tsanetconnect__Token__c = :token
            WITH SECURITY_ENFORCED
        ];
    }

    /**
     * Fields required to (re)build a Chatter FeedItem from a note.
     * Runs WITH SYSTEM_MODE because the only caller is the Platform Event subscriber,
     * which executes as the Automated Process User and must succeed regardless of FLS.
     * @param ids set of TSANetNote__c record Ids
     * @return matching TSANetNote__c records with feed-item fields populated
     */
    public static tsanetconnect__TSANetNote__c[] getForFeedItemBuild(Set<Id> ids) {
        return [
            SELECT Id, tsanetconnect__Token__c, tsanetconnect__isCaseFeed__c,
                   tsanetconnect__TSANetCase__c, tsanetconnect__FeedItemId__c,
                   tsanetconnect__CreatedAt__c, tsanetconnect__Description__c,
                   tsanetconnect__Summary__c, tsanetconnect__CompanyName__c,
                   tsanetconnect__CreatorName__c
            FROM tsanetconnect__TSANetNote__c
            WHERE Id IN :ids
            WITH SYSTEM_MODE
        ];
    }
}
