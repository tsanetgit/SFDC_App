/** Queueable job that fetches TSANet collaboration cases in paginated batches. */
public inherited sharing class TSANetQueueableJob implements Queueable, Database.AllowsCallouts {

    /** Maximum number of pages to process per execution. */
    public static Integer EXECUTE_LIMIT = TSANetConstants.PAGE_SIZE;

    /** Accumulated TSANet case records keyed by token. */
    public Map<String, tsanetconnect__TSANetCase__c> cases = new Map<String, tsanetconnect__TSANetCase__c>();
    /** Accumulated TSANet response records keyed by response ID. */
    public Map<String, tsanetconnect__TSANetResponse__c> responses = new Map<String, tsanetconnect__TSANetResponse__c>();
    /** Accumulated TSANet note records keyed by token. */
    public Map<String, tsanetconnect__TSANetNote__c> notes = new Map<String, tsanetconnect__TSANetNote__c>();

    /** Access token for TSANet API authentication. */
    public String token;
    /** Optional case number filter. */
    public String caseNumber;

    /** Current page being processed. */
    public Integer currentPage;
    /** Total number of pages available. */
    public Integer totalPages;

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


    /** Processes TSANet collaboration cases asynchronously.
     * @param qc queueable context provided by the platform
     */
    public void execute(QueueableContext qc) {

        if (String.isBlank(this.token) && !Test.isRunningTest()) {
            this.token = TSANetService.getTSANetAccessToken();
        }

        Boolean stopProcessing = false;
        Integer count = 0;

        while (count < EXECUTE_LIMIT) {
            try {
                TSANetData data = getTSANetCollaborationCases(this.token, this.currentPage);

                if (data.cases.isEmpty()) {
                    stopProcessing = true;
                    break;
                }

                for(tsanetconnect__TSANetCase__c caseRecord : data.cases){
                    this.cases.put(caseRecord.tsanetconnect__Token__c, caseRecord);
                }
                for(tsanetconnect__TSANetResponse__c response : data.responses){
                    this.responses.put(response.tsanetconnect__tsaNetResponseId__c, response);
                }
                for(tsanetconnect__TSANetNote__c note : data.notes){
                    this.notes.put(note.tsanetconnect__Token__c, note);
                }

                currentPage++;
                count++;
            } catch (Exception e) {
                ErrorLogger.logError(e, 'TSANET_QUEUEABLE_JOB_ERROR');
                stopProcessing = true;
                break;
            }
        }

        if (!stopProcessing && !Test.isRunningTest()) {
            TSANetQueueableJob nextJob = new TSANetQueueableJob(currentPage, totalPages, cases, responses, notes, caseNumber);
            nextJob.token = this.token;
            System.enqueueJob(nextJob);
        } else {
            TSANetData data = new TSANetData();
            data.cases = reverseList(cases.values());
            data.notes = reverseList(notes.values());
            data.responses = reverseList(responses.values());
            TSANetService.upsertTSANetData(data);

            if(token != NULL){
                CredentialManager.updateToken(token);
            }
        }
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
     * @param token access token for authentication
     * @param page page number to retrieve
     * @return parsed TSANet data containing cases, responses, and notes
     */
    public TSANetData getTSANetCollaborationCases(String token, Integer page){
        String path = EndpointManager.getCollaborationCasesPath(this.caseNumber);
        path += (this.caseNumber != null ? '&' : '?');
        path += 'paginated=true&page=' + page + '&size=' + TSANetConstants.PAGE_SIZE;

        HttpResponse res = HttpClient.sendGet(path, token);

        TSANetCaseDataResponse data = TSANetCaseDataResponse.parse(res.getBody());

		this.totalPages = data.totalPages;

        return ParserManager.parseTSANetCases(System.JSON.serialize(data.content), null);
    }
}
