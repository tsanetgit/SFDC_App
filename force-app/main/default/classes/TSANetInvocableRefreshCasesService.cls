/** Invocable service that enqueues a refresh job for TSANet cases. */
global with sharing class TSANetInvocableRefreshCasesService {

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
     * @return one result per input, in the same order
     */
    @InvocableMethod(label='Refresh TSANet Cases' description='Returns the result as boolean' category='TSANet')
    global static TSANetRefreshResult[] refreshTSANetCases(String[] caseId) {
        TSANetRefreshResult[] results = new TSANetRefreshResult[]{};
        if (caseId == null) {
            return results;
        }

        for (String caseRecordId : caseId) {
            TSANetRefreshResult refreshResult = new TSANetRefreshResult();
            try {
                String caseNumber = null;
                if (String.isNotBlank(caseRecordId)) {
                    Case sfCase = CaseSelector.getById(caseRecordId);
                    caseNumber = sfCase.CaseNumber;
                }
                refreshResult.result = TSANetQueueableJob.enqueueIfConnected(caseNumber);
            } catch (Exception e) {
                ErrorLogger.logError(e, 'TSANET_INVOCABLE_REFRESH_ERROR');
                refreshResult.result = false;
            }
            results.add(refreshResult);
        }
        return results;
    }
}
