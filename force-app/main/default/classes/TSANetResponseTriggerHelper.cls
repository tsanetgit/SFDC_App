public with sharing class TSANetResponseTriggerHelper {
    
    public static void assignEngineerInfo(tsanetconnect__TSANetResponse__c[] responses){
        
        try {
            String[] tsaNetExternalCaseIds = new String[]{};
                
            Map<String, tsanetconnect__TSANetResponse__c> caseIdToResponses = new Map<String, tsanetconnect__TSANetResponse__c>();
            for(tsanetconnect__TSANetResponse__c response : responses){
                caseIdToResponses.put(response.tsanetconnect__CaseId__c, response);
            }
            
            if(caseIdToResponses.keySet().size() == 0){ return; }
    
            tsanetconnect__TSANetCase__c[] tsaNetCases = [SELECT Id, Name, tsanetconnect__Case__c, tsanetconnect__EngineerName__c, tsanetconnect__EngineerPhone__c, tsanetconnect__EngineerEmail__c, tsanetconnect__tsaNetCaseId__c, tsanetconnect__Partner__c FROM tsanetconnect__TSANetCase__c WHERE tsanetconnect__tsaNetCaseId__c IN:caseIdToResponses.keySet() WITH SECURITY_ENFORCED ];
    
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
    

    public static void findRelationships(tsanetconnect__TSANetResponse__c[] responses){
        try {
            
            String[] tsaNetExternalCaseIds = new String[]{};
                
            for(tsanetconnect__TSANetResponse__c response : responses){
                if(response.tsanetconnect__tsaNetCase__c == NULL && response.tsanetconnect__CaseId__c != NULL){
                    tsaNetExternalCaseIds.add(response.tsanetconnect__CaseId__c);
                }
            }
            
            if(tsaNetExternalCaseIds.size() == 0){ return; }
    
            tsanetconnect__TSANetCase__c[] tsaNetCases = [SELECT Id, Name, OwnerId, tsanetconnect__Case__c, tsanetconnect__tsaNetCaseId__c, tsanetconnect__Partner__c FROM tsanetconnect__TSANetCase__c WHERE tsanetconnect__tsaNetCaseId__c IN:tsaNetExternalCaseIds WITH SECURITY_ENFORCED ];
 
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