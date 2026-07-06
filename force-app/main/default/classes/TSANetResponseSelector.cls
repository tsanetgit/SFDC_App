/** Centralized SOQL for tsanetconnect__TSANetResponse__c. */
public with sharing class TSANetResponseSelector {

    /**
     * Responses by parent TSANetCase external IDs (for trigger context).
     * @param externalCaseIds set of external case IDs to query by
     * @return list of matching TSANetResponse__c records
     */
    public static tsanetconnect__TSANetResponse__c[] getByExternalCaseIds(Set<String> externalCaseIds) {
        return [
            SELECT Id, Name, tsanetconnect__TSANetCase__c, tsanetconnect__Type__c,
                   tsanetconnect__EngineerName__c, tsanetconnect__EngineerPhone__c,
                   tsanetconnect__EngineerEmail__c, tsanetconnect__Note__c,
                   tsanetconnect__tsaNetCaseId__c, tsanetconnect__tsaNetResponseId__c
            FROM tsanetconnect__TSANetResponse__c
            WHERE tsanetconnect__tsaNetCaseId__c IN :externalCaseIds
            WITH USER_MODE
            ORDER BY tsanetconnect__CreatedAt__c DESC
        ];
    }
}
