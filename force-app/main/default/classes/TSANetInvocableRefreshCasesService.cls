/** Invocable service that enqueues a refresh job for TSANet cases. */
global inherited sharing class TSANetInvocableRefreshCasesService {

    /** @deprecated Credentials are now resolved internally by TSANetService. */
    @Deprecated
    global static tsanetconnect__TSANet_Credentials__c credential;

    /** Result wrapper containing the refresh operation outcome. */
	global class TSANetRefreshResult {
        /** True if the refresh job was enqueued successfully. */
        @InvocableVariable
        global Boolean result;
    }

    /**
     * Enqueues an asynchronous job to refresh TSANet cases, optionally filtered by Case Id.
     * @param caseId list containing an optional Salesforce Case Id to scope the refresh
     * @return list of TSANetRefreshResult indicating whether the job was enqueued
     */
    @InvocableMethod(label='Refresh TSANet Cases' description='Returns the result as boolean' category='TSANet')
    global static TSANetRefreshResult[] refreshTSANetCases(String[] caseId) {
        String caseRecordId = null;
        if(caseId.size() > 0){
            caseRecordId = caseId[0];
        }
        Boolean result = false;
        try {
            String caseNumber = null;
            if(caseRecordId != null){
                Case sfCase = CaseSelector.getById(caseRecordId);
                caseNumber = sfCase.CaseNumber;
            }
            System.enqueueJob(new TSANetQueueableJob(0, null, null, null, null, caseNumber));
            result = true;
        } catch(Exception e){
            ErrorLogger.logError(e, 'TSANET_INVOCABLE_REFRESH_ERROR');
        }

        TSANetRefreshResult refreshResult = new TSANetRefreshResult();
        refreshResult.result = result;
        return new TSANetRefreshResult[]{ refreshResult };
    }
}
