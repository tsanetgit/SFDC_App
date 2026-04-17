/** Handles before-insert trigger logic for TSANetCase records. */
public with sharing class TSANetCaseTriggerHandler {

    /**
     * Entry point for the before-insert trigger on TSANetCase.
     * @param cases list of TSANetCase records being inserted
     */
    public static void handleBeforeInsert(tsanetconnect__TSANetCase__c[] cases){
        findRelationships(cases);
    }

    /**
     * Links incoming TSANetCase records to their parent Case by matching case numbers.
     * @param cases list of TSANetCase records to link
     */
    public static void findRelationships(tsanetconnect__TSANetCase__c[] cases){

        String[] caseNumbers = new String[]{};

        for(tsanetconnect__TSANetCase__c caseRecord : cases){
            caseNumbers.add(caseRecord.tsanetconnect__SubmitterCaseNumber__c);
            caseNumbers.add(caseRecord.tsanetconnect__ReceiverCaseNumber__c);
        }
        if(caseNumbers.size() == 0){ return; }

        Case[] sfCases = CaseSelector.getByCaseNumbers(new Set<String>(caseNumbers));
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
