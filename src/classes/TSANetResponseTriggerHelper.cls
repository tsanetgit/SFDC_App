public class TSANetResponseTriggerHelper {
    
    public static void assignEngineerInfo(tsanet_connect__TSANetResponse__c[] responses){
        
        try {
            String[] tsaNetExternalCaseIds = new String[]{};
                
            Map<String, tsanet_connect__TSANetResponse__c> caseIdToResponses = new Map<String, tsanet_connect__TSANetResponse__c>();
            for(tsanet_connect__TSANetResponse__c response : responses){
                caseIdToResponses.put(response.tsanet_connect__CaseId__c, response);
            }
            
            if(caseIdToResponses.keySet().size() == 0){ return; }
    
            tsanet_connect__TSANetCase__c[] tsaNetCases = [SELECT Id, Name, tsanet_connect__Case__c, tsanet_connect__EngineerName__c, tsanet_connect__EngineerPhone__c, tsanet_connect__EngineerEmail__c, tsanet_connect__tsaNetCaseId__c, tsanet_connect__Partner__c FROM tsanet_connect__TSANetCase__c WHERE tsanet_connect__tsaNetCaseId__c IN:caseIdToResponses.keySet()];
    
            for(tsanet_connect__TSANetCase__c tsaNetCase : tsaNetCases){
                if(caseIdToResponses.containsKey(tsaNetCase.tsanet_connect__tsaNetCaseId__c)){
                    tsanet_connect__TSANetResponse__c caseResponse = caseIdToResponses.get(tsaNetCase.tsanet_connect__tsaNetCaseId__c);
                    tsaNetCase.tsanet_connect__EngineerName__c = caseResponse.tsanet_connect__EngineerName__c;
                    tsaNetCase.tsanet_connect__EngineerPhone__c = caseResponse.tsanet_connect__EngineerPhone__c;
                    tsaNetCase.tsanet_connect__EngineerEmail__c = caseResponse.tsanet_connect__EngineerEmail__c;
                }
            }
            
            update tsaNetCases;
        } catch(Exception e){
            ErrorLogger.logError(e, 'TSANET_RESPONSE_ENGINEER_DATA_MAPPING_ERROR');
        }
    }
    

    public static void findRelationships(tsanet_connect__TSANetResponse__c[] responses){
        try {
            
            String[] tsaNetExternalCaseIds = new String[]{};
                
            for(tsanet_connect__TSANetResponse__c response : responses){
                if(response.tsanet_connect__tsaNetCase__c == NULL && response.tsanet_connect__CaseId__c != NULL){
                    tsaNetExternalCaseIds.add(response.tsanet_connect__CaseId__c);
                }
            }
            
            if(tsaNetExternalCaseIds.size() == 0){ return; }
    
            tsanet_connect__TSANetCase__c[] tsaNetCases = [SELECT Id, Name, tsanet_connect__Case__c, tsanet_connect__tsaNetCaseId__c, tsanet_connect__Partner__c FROM tsanet_connect__TSANetCase__c WHERE tsanet_connect__tsaNetCaseId__c IN:tsaNetExternalCaseIds];
 
            Map<String, tsanet_connect__TSANetCase__c> externalIdToCase = new Map<String, tsanet_connect__TSANetCase__c>();
            for(tsanet_connect__TSANetCase__c tsaNetCase : tsaNetCases){
                externalIdToCase.put(tsaNetCase.tsanet_connect__tsaNetCaseId__c, tsaNetCase);
            }
            
            for(tsanet_connect__TSANetResponse__c response : responses){
                if(externalIdToCase.containsKey(response.tsanet_connect__CaseId__c)){
                    tsanet_connect__TSANetCase__c tsaNetCase = externalIdToCase.get(response.tsanet_connect__CaseId__c);
                    response.tsanet_connect__TSANetCase__c = tsaNetCase.Id;
                }
            } 
        } catch(Exception e){
            ErrorLogger.logError(e, 'TSANET_RESPONSE_FIND_RELATIONSHIPS_ERROR');
        }
    }
}