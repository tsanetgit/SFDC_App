/** Helper logic for the TSANetResponse__c trigger handler. */
public with sharing class TSANetResponseTriggerHelper {

    /**
     * Copies engineer contact details from responses to their parent TSANet cases.
     * @param responses newly inserted TSANetResponse__c records
     */
    public static void assignEngineerInfo(tsanetconnect__TSANetResponse__c[] responses){

        try {
            Map<String, tsanetconnect__TSANetResponse__c> caseIdToResponses = new Map<String, tsanetconnect__TSANetResponse__c>();
            for(tsanetconnect__TSANetResponse__c response : responses){
                caseIdToResponses.put(response.tsanetconnect__CaseId__c, response);
            }

            if(caseIdToResponses.keySet().size() == 0){ return; }

            tsanetconnect__TSANetCase__c[] tsaNetCases = TSANetCaseSelector.getByExternalCaseIds(caseIdToResponses.keySet());

            for(tsanetconnect__TSANetCase__c tsaNetCase : tsaNetCases){
                if(caseIdToResponses.containsKey(tsaNetCase.tsanetconnect__tsaNetCaseId__c)){
                    tsanetconnect__TSANetResponse__c caseResponse = caseIdToResponses.get(tsaNetCase.tsanetconnect__tsaNetCaseId__c);
                    tsaNetCase.tsanetconnect__EngineerName__c = caseResponse.tsanetconnect__EngineerName__c;
                    tsaNetCase.tsanetconnect__EngineerPhone__c = caseResponse.tsanetconnect__EngineerPhone__c;
                    tsaNetCase.tsanetconnect__EngineerEmail__c = caseResponse.tsanetconnect__EngineerEmail__c;
                }
            }

            Database.update(tsaNetCases, AccessLevel.USER_MODE);
        } catch(Exception e){
            ErrorLogger.logError(e, 'TSANET_RESPONSE_ENGINEER_DATA_MAPPING_ERROR');
        }
    }


    /**
     * Links TSANetResponse__c records to their parent TSANetCase__c by external case ID.
     * @param responses TSANetResponse__c records to resolve relationships for
     */
    public static void findRelationships(tsanetconnect__TSANetResponse__c[] responses){
        try {

            String[] tsaNetExternalCaseIds = new String[]{};

            for(tsanetconnect__TSANetResponse__c response : responses){
                if(response.tsanetconnect__tsaNetCase__c == NULL && response.tsanetconnect__CaseId__c != NULL){
                    tsaNetExternalCaseIds.add(response.tsanetconnect__CaseId__c);
                }
            }

            if(tsaNetExternalCaseIds.size() == 0){ return; }

            tsanetconnect__TSANetCase__c[] tsaNetCases = TSANetCaseSelector.getByExternalCaseIds(new Set<String>(tsaNetExternalCaseIds));

            Map<String, tsanetconnect__TSANetCase__c> externalIdToCase = new Map<String, tsanetconnect__TSANetCase__c>();
            for(tsanetconnect__TSANetCase__c tsaNetCase : tsaNetCases){
                externalIdToCase.put(tsaNetCase.tsanetconnect__tsaNetCaseId__c, tsaNetCase);
            }

            for(tsanetconnect__TSANetResponse__c response : responses){
                if(externalIdToCase.containsKey(response.tsanetconnect__CaseId__c)){
                    tsanetconnect__TSANetCase__c tsaNetCase = externalIdToCase.get(response.tsanetconnect__CaseId__c);
                    response.tsanetconnect__TSANetCase__c = tsaNetCase.Id;
                    response.OwnerId = tsaNetCase.OwnerId;
                }
            }
        } catch(Exception e){
            ErrorLogger.logError(e, 'TSANET_RESPONSE_FIND_RELATIONSHIPS_ERROR');
        }
    }
}