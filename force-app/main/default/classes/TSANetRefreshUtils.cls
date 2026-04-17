/** Utility for refreshing TSANet collaboration data via Visualforce or Lightning. */
public inherited sharing class TSANetRefreshUtils {

    /**
     * Constructs the controller extension for Visualforce page binding.
     * @param controller standard controller instance
     */
    public TSANetRefreshUtils(ApexPages.StandardController controller) {
        // Required by Visualforce page binding
    }

    /**
     * Enqueues a job to refresh all TSANet data and redirects back.
     * @return page reference to the TSANet case list view
     */
    public PageReference refresh() {
        try {
            System.enqueueJob(new TSANetQueueableJob(0, null, null, null, null, null));
            PageReference returnPage = goBack();
            return returnPage;

        } catch(Exception e){
            PageReference returnPage = goBack();
            return returnPage;
        }
    }

    /**
     * Returns a page reference to the TSANet case list view.
     * @return page reference to the list view
     */
    public PageReference goBack() {
        return new PageReference('/lightning/o/tsanetconnect__TSANetCase__c/list');
    }

    /**
     * Enqueues a refresh job scoped to a specific case.
     * @param caseId Salesforce Case record ID to refresh for
     * @return true when the job is enqueued
     */
    @AuraEnabled
    public static Boolean refreshOnCase(Id caseId) {
        try {
            String caseNumber = null;
            if(caseId != null){
                Case sfCase = CaseSelector.getById(caseId);
                caseNumber = sfCase.CaseNumber;
            }
            System.enqueueJob(new TSANetQueueableJob(0, null, null, null, null, caseNumber));
            return true;
        } catch(Exception e){
            return true;
        }
    }

}
