global class TSANetInvocableRefreshCasesService {

    global static tsanetconnect__TSANet_Credentials__c credential = CredentialManager.getCredentials();
    
	global class TSANetRefreshResult {
        @InvocableVariable 
        global Boolean result;
    }
    
    @InvocableMethod(label='Refresh TSANet Cases' description='Returns the result as boolean' category='TSANet')
    global static TSANetRefreshResult[] refreshTSANetCases(String[] caseId) {
        String caseRecordId = null;
        if(caseId.size() > 0){
            caseRecordId = caseId[0];
        }
        Boolean result = false;
        try {
            TSANetService.getRelatedCollaborationCases(caseRecordId, null);   
            result = true;
        } catch(Exception e){}

        TSANetRefreshResult refreshResult = new TSANetRefreshResult();
        refreshResult.result = result;
        return new TSANetRefreshResult[]{ refreshResult };
    }
}