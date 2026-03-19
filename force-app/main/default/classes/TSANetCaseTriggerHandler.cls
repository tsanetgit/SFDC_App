public with sharing class TSANetCaseTriggerHandler {
    
    public static void handleBeforeInsert(tsanetconnect__TSANetCase__c[] cases){
        findRelationships(cases);
    }
    
    public static void handleAfterUpdate(tsanetconnect__TSANetCase__c[] cases, Map<Id, tsanetconnect__TSANetCase__c> oldCases){
        updateTSANetOwner(cases, oldCases);
    }

    public static void updateTSANetOwner(tsanetconnect__TSANetCase__c[] cases, Map<Id, tsanetconnect__TSANetCase__c> oldCases){
        tsanetconnect__TSANetCase__c[] casesWithNewOwner = new tsanetconnect__TSANetCase__c[]{};
        for(tsanetconnect__TSANetCase__c caseRecord : cases){
            if(isChangedCase(caseRecord, oldCases)){
                TSANetService.changeTSANetOwner(caseRecord.Id, null);
            }
        }
    }
    
    public static Boolean isChangedCase(tsanetconnect__TSANetCase__c caseRecord, Map<Id, tsanetconnect__TSANetCase__c> oldCases){
        return oldCases.containsKey(caseRecord.Id) && caseRecord.tsanetconnect__Case__c != NULL && caseRecord.tsanetconnect__Case__c != oldCases.get(caseRecord.Id).tsanetconnect__Case__c;
    }
    
    public static void findRelationships(tsanetconnect__TSANetCase__c[] cases){
        
        String[] caseNumbers = new String[]{};
            
        for(tsanetconnect__TSANetCase__c caseRecord : cases){
            caseNumbers.add(caseRecord.tsanetconnect__SubmitterCaseNumber__c);
            caseNumbers.add(caseRecord.tsanetconnect__ReceiverCaseNumber__c);
        }
        if(caseNumbers.size() == 0){ return; }

        Case[] sfCases = [SELECT Id, OwnerId, CaseNumber FROM Case WHERE CaseNumber IN:caseNumbers WITH SECURITY_ENFORCED ];
        Map<String, Case> caseNumberToCase = new Map<String, Case>();
        for(Case sfCase : sfCases){
            caseNumberToCase.put(sfCase.CaseNumber, sfCase);
        }
        for(tsanetconnect__TSANetCase__c caseRecord : cases){
            if(caseNumberToCase.containsKey(caseRecord.tsanetconnect__SubmitterCaseNumber__c)){
                Case relatedCase = caseNumberToCase.get(caseRecord.tsanetconnect__SubmitterCaseNumber__c);
                caseRecord.tsanetconnect__Case__c = relatedCase.Id;
                caseRecord.OwnerId = relatedCase.OwnerId;
            } else {
                if(caseNumberToCase.containsKey(caseRecord.tsanetconnect__ReceiverCaseNumber__c)){
                    Case relatedCase = caseNumberToCase.get(caseRecord.tsanetconnect__ReceiverCaseNumber__c);
                    caseRecord.tsanetconnect__Case__c = relatedCase.Id;
                    caseRecord.OwnerId = relatedCase.OwnerId;
                }
            }
        }        
    }
}