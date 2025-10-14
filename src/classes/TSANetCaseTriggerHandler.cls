public class TSANetCaseTriggerHandler {
    
    public static void handleBeforeInsert(tsanet_connect__TSANetCase__c[] cases){
        System.debug('HANDLE BEFORE INSERT');
        findRelationships(cases);
    }
    
    public static void handleAfterUpdate(tsanet_connect__TSANetCase__c[] cases, Map<Id, tsanet_connect__TSANetCase__c> oldCases){
        updateTSANetOwner(cases, oldCases);
    }

    public static void updateTSANetOwner(tsanet_connect__TSANetCase__c[] cases, Map<Id, tsanet_connect__TSANetCase__c> oldCases){
        tsanet_connect__TSANetCase__c[] casesWithNewOwner = new tsanet_connect__TSANetCase__c[]{};
        for(tsanet_connect__TSANetCase__c caseRecord : cases){
            if(oldCases.containsKey(caseRecord.Id) && caseRecord.OwnerId != NULL && caseRecord.OwnerId != oldCases.get(caseRecord.Id).OwnerId){
                TSANetService.changeTSANetOwner(caseRecord.Id, null);
            }
        }
    }
    
    public static void findRelationships(tsanet_connect__TSANetCase__c[] cases){
        
        String[] caseNumbers = new String[]{};
            
        for(tsanet_connect__TSANetCase__c caseRecord : cases){
            caseNumbers.add(caseRecord.tsanet_connect__SubmitterCaseNumber__c);
            caseNumbers.add(caseRecord.tsanet_connect__ReceiverCaseNumber__c);
        }
        System.debug('caseNumbers: ' + caseNumbers);
        if(caseNumbers.size() == 0){ return; }

        Case[] sfCases = [SELECT Id, CaseNumber FROM Case WHERE CaseNumber IN:caseNumbers];
        Map<String, Case> caseNumberToCase = new Map<String, Case>();
        for(Case sfCase : sfCases){
            caseNumberToCase.put(sfCase.CaseNumber, sfCase);
        }
        System.debug('caseNumberToCase: ' + caseNumberToCase);
        for(tsanet_connect__TSANetCase__c caseRecord : cases){
            if(caseNumberToCase.containsKey(caseRecord.tsanet_connect__SubmitterCaseNumber__c)){
                Case relatedCase = caseNumberToCase.get(caseRecord.tsanet_connect__SubmitterCaseNumber__c);
                caseRecord.tsanet_connect__Case__c = relatedCase.Id;
            } else {
                if(caseNumberToCase.containsKey(caseRecord.tsanet_connect__ReceiverCaseNumber__c)){
                    Case relatedCase = caseNumberToCase.get(caseRecord.tsanet_connect__ReceiverCaseNumber__c);
                    caseRecord.tsanet_connect__Case__c = relatedCase.Id;
                }
            }
        }        
    }
    
    
}