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
}
