public class CaseTriggerHandler {

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
        
        tsanet_connect__TSANetCase__c[] tsaNetCases = [SELECT Id, Name FROM tsanet_connect__TSANetCase__c WHERE tsanet_connect__Case__c IN:caseIds];
        
        for(tsanet_connect__TSANetCase__c caseRecord : tsaNetCases){
            if(!Test.isRunningTest()){
                TSANetService.changeTSANetOwner(caseRecord.Id, null);
            }
        }
    }
}