/** Queueable job that fetches TSANet collaboration cases in paginated batches. */
public inherited sharing class TSANetQueueableJob implements Queueable, Database.AllowsCallouts, Finalizer {

    /** Maximum number of pages to process per execution. */
    public static Integer EXECUTE_LIMIT = TSANetConstants.PAGE_SIZE;

    /** Accumulated TSANet case records keyed by token. */
    public Map<String, tsanetconnect__TSANetCase__c> cases = new Map<String, tsanetconnect__TSANetCase__c>();
    /** Accumulated TSANet response records keyed by response ID. */
    public Map<String, tsanetconnect__TSANetResponse__c> responses = new Map<String, tsanetconnect__TSANetResponse__c>();
    /** Accumulated TSANet note records keyed by token. */
    public Map<String, tsanetconnect__TSANetNote__c> notes = new Map<String, tsanetconnect__TSANetNote__c>();

    /** Optional case number filter. */
    public String caseNumber;

    /** Current page being processed. */
    public Integer currentPage;
    /** Total number of pages available. */
    public Integer totalPages;

    /** True when the Finalizer should start a new queueable for the next page. */
    @TestVisible
    Boolean chainNext;
    /** Next page job; enqueued from the Finalizer so stack depth resets to 1. */
    TSANetQueueableJob nextJob;

    /**
     * Enqueues a collaboration-case sync when the primary credential is connected.
     * @param caseNumber optional case number filter
     * @return true when the job was enqueued
     */
    public static Boolean enqueueIfConnected(String caseNumber){
        if(!CredentialManager.isConnected()){
            return false;
        }
        System.enqueueJob(new TSANetQueueableJob(0, null, null, null, null, caseNumber));
        return true;
    }

    /**
     * Constructs a queueable job for paginated TSANet data retrieval.
     * @param currentPage page number to start from
     * @param totalPages total pages available
     * @param cases previously accumulated case records
     * @param responses previously accumulated response records
     * @param notes previously accumulated note records
     * @param caseNumber optional case number filter
     */
    public TSANetQueueableJob(Integer currentPage,
                              Integer totalPages,
                              Map<String, tsanetconnect__TSANetCase__c> cases,
                              Map<String, tsanetconnect__TSANetResponse__c> responses,
                              Map<String, tsanetconnect__TSANetNote__c> notes,
                              String caseNumber){

        this.currentPage = currentPage;
        this.totalPages = totalPages != NULL ? totalPages : 1;
        this.cases = cases != NULL ? cases : new Map<String, tsanetconnect__TSANetCase__c>();
        this.responses = responses != NULL ? responses : new Map<String, tsanetconnect__TSANetResponse__c>();
        this.notes = notes != NULL ? notes : new Map<String, tsanetconnect__TSANetNote__c>();
        this.caseNumber = caseNumber;
    }


    /**
     * Fetches and persists one page. The next page is enqueued from the Finalizer
     * so Salesforce resets queueable stack depth (max 5 if chained from execute).
     * @param qc queueable context provided by the platform
     */
    public void execute(QueueableContext qc) {
        System.attachFinalizer(this);
        try {
            TSANetData data = getTSANetCollaborationCases(this.currentPage);
            if (data == null || data.cases == null || data.cases.isEmpty()) {
                persist();
                return;
            }

            accumulate(data);
            persist();

            Integer nextPage = this.currentPage + 1;
            Boolean morePages = data.cases.size() >= TSANetConstants.PAGE_SIZE
                && (this.totalPages == null || nextPage < this.totalPages);

            // Test.isRunningTest is unavoidable: tests cannot chain a queueable.
            if (morePages && !Test.isRunningTest()) {
                this.chainNext = true;
                this.nextJob = new TSANetQueueableJob(nextPage, totalPages, null, null, null, caseNumber);
            }
        } catch (Exception e) {
            this.chainNext = false;
            ErrorLogger.logError(e, 'TSANET_QUEUEABLE_JOB_ERROR', new Map<String, String>{
                'caseNumber' => this.caseNumber,
                'page' => String.valueOf(this.currentPage)
            });
            if(isAuthenticationFailure(e)){
                disconnectPrimaryCredential();
            }
            persist();
        }
    }

    /**
     * Starts the next page in a new queueable chain after this job succeeds.
     * @param ctx finalizer context for the parent queueable
     */
    public void execute(FinalizerContext ctx) {
        if (this.chainNext == true
            && this.nextJob != null
            && ctx.getResult() == ParentJobResult.SUCCESS) {
            System.enqueueJob(this.nextJob);
        }
    }

    /** True when the exception indicates invalid or missing TSANet credentials. */
    @TestVisible
    static Boolean isAuthenticationFailure(Exception e){
        if(e == null || String.isBlank(e.getMessage())){
            return false;
        }
        String message = e.getMessage().toLowerCase();
        return message.contains('unauthorized')
            || message.contains('oauth token')
            || message.contains('unable to fetch the oauth');
    }

    /** Marks the primary credential disconnected and aborts its scheduled jobs. */
    private static void disconnectPrimaryCredential(){
        try {
            InternalProcessManager.markDisconnected(CredentialManager.getCredentials());
        } catch (Exception e) {
            ErrorLogger.logError(e, 'TSANET_QUEUEABLE_JOB_DISCONNECT');
        }
    }

    /** Merges one page of parsed records into the job accumulators. */
    private void accumulate(TSANetData data){
        for(tsanetconnect__TSANetCase__c caseRecord : data.cases){
            this.cases.put(caseRecord.tsanetconnect__Token__c, caseRecord);
        }
        for(tsanetconnect__TSANetResponse__c response : data.responses){
            this.responses.put(response.tsanetconnect__tsaNetResponseId__c, response);
        }
        for(tsanetconnect__TSANetNote__c note : data.notes){
            this.notes.put(note.tsanetconnect__Token__c, note);
        }
    }

    /** Upserts the current page after the callout has finished. */
    private void persist(){
        TSANetData data = new TSANetData();
        data.cases = reverseList(cases.values());
        data.notes = reverseList(notes.values());
        data.responses = reverseList(responses.values());
        TSANetService.upsertTSANetData(data);
    }

    /** Reverses the order of a list of SObjects.
     * @param items list to reverse
     * @return new list in reverse order
     */
    private static List<SObject> reverseList(List<SObject> items) {
        List<SObject> reversed = new List<SObject>();
        for (Integer i = items.size() - 1; i >= 0; i--) {
            reversed.add(items[i]);
        }
        return reversed;
    }

    /**
     * Fetches a page of collaboration cases from the TSANet API.
     * @param page page number to retrieve
     * @return parsed TSANet data containing cases, responses, and notes
     */
    public TSANetData getTSANetCollaborationCases(Integer page){
        return parsePage(TSANetAPIService.getCollaborationCasesPage(this.caseNumber, page));
    }

    /**
     * Parses a page of collaboration cases and records the total page count.
     * @param body raw API response body for the page
     * @return parsed TSANet data for the page
     */
    private TSANetData parsePage(String body){
        TSANetCaseDataResponse data = TSANetCaseDataResponse.parse(body);

        this.totalPages = data.totalPages;

        return ParserManager.parseTSANetCases(System.JSON.serialize(data.content), null);
    }
}
