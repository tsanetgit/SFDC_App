public with sharing class CaseTriggerHandler {

    public static void handleAfterUpdate(Case[] cases, Map<Id, Case> oldCases){
        updateTSANetOwner(cases, oldCases);
    }

    public static void updateTSANetOwner(Case[] cases, Map<Id, Case> oldCases){
        
        Id[] caseIds = new Id[]{};
        for(Case sfCase : cases){
            if(oldCases.containsKey(sfCase.Id) && sfCase.OwnerId != NULL && sfCase.OwnerId != oldCases.get(sfCase.Id).OwnerId){
                caseIds.add(sfCase.Id);
            }
        }
        
        tsanetconnect__TSANetCase__c[] tsaNetCases = [SELECT Id, Name FROM tsanetconnect__TSANetCase__c WHERE tsanetconnect__Case__c IN:caseIds WITH SECURITY_ENFORCED ];
        
        for(tsanetconnect__TSANetCase__c caseRecord : tsaNetCases){
            if(!Test.isRunningTest()){ TSANetService.changeTSANetOwner(caseRecord.Id, null); }
        }
    }
}