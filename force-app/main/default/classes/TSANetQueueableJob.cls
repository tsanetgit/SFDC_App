public class TSANetQueueableJob implements Queueable, Database.AllowsCallouts {
    
    public static Integer EXECUTE_LIMIT = 50;
    
    public Map<String, tsanetconnect__TSANetCase__c> cases = new Map<String, tsanetconnect__TSANetCase__c>();
    public Map<String, tsanetconnect__TSANetResponse__c> responses = new Map<String, tsanetconnect__TSANetResponse__c>();
    public Map<String, tsanetconnect__TSANetNote__c> notes = new Map<String, tsanetconnect__TSANetNote__c>();
    
    public String token;
        
    public Integer currentPage;
    public Integer totalPages;
    
    public TSANetQueueableJob(Integer currentPage,
                              Integer totalPages,
                              Map<String, tsanetconnect__TSANetCase__c> cases, 
                              Map<String, tsanetconnect__TSANetResponse__c> responses, 
                              Map<String, tsanetconnect__TSANetNote__c> notes){
                                  
        this.currentPage = currentPage;
        this.totalPages = totalPages != NULL ? totalPages : 1;
        this.cases = cases != NULL ? cases : new Map<String, tsanetconnect__TSANetCase__c>();
        this.responses = responses != NULL ? responses : new Map<String, tsanetconnect__TSANetResponse__c>();
        this.notes = notes != NULL ? notes : new Map<String, tsanetconnect__TSANetNote__c>();
    }
    
    
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
                stopProcessing = true;
                break;
            }
        }

        if (!stopProcessing && !Test.isRunningTest()) {
            TSANetQueueableJob nextJob = new TSANetQueueableJob(currentPage, totalPages, cases, responses, notes);
            nextJob.token = this.token;
            System.enqueueJob(nextJob);
        } else {
            Database.UpsertResult[] tsaNetCaseResult = Database.upsert(cases.values(), tsanetconnect__TSANetCase__c.tsanetconnect__Token__c, false, AccessLevel.USER_MODE);
            
            Database.UpsertResult[] tsaNetNoteResult = Database.upsert(notes.values(), tsanetconnect__TSANetNote__c.tsanetconnect__Token__c, false, AccessLevel.USER_MODE);
            
            Database.UpsertResult[] tsaNetResponseResult = Database.upsert(responses.values(), tsanetconnect__TSANetResponse__c.tsanetconnect__tsaNetResponseId__c, false, AccessLevel.USER_MODE);
            
            tsanetconnect__TSANetError__c[] errors = new tsanetconnect__TSANetError__c[]{};
    
            errors.addAll(ErrorManager.collectErrors(tsaNetCaseResult, cases.values(), tsanetconnect__TSANetCase__c.tsanetconnect__Token__c));
            errors.addAll(ErrorManager.collectErrors(tsaNetNoteResult, notes.values(), tsanetconnect__TSANetNote__c.tsanetconnect__Token__c));
            errors.addAll(ErrorManager.collectErrors(tsaNetResponseResult, responses.values(), tsanetconnect__TSANetResponse__c.tsanetconnect__tsaNetResponseId__c));
            ErrorLogger.logErrors(errors);
            
            if(token != NULL){
                CredentialManager.updateToken(token);
            }
        }
    }

    public TSANetData getTSANetCollaborationCases(String token, Integer page){
 
        
        String path = EndpointManager.domain + '/v1/collaboration-requests?paginated=true&page=' + page + '&size=50';
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(path);
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        
        TSANetCaseDataResponse data = TSANetCaseDataResponse.parse(res.getBody());
        
		this.totalPages = data.totalPages;
        
        return ParserManager.parseTSANetCases(System.JSON.serialize(data.content), null);
    }
    
    
}