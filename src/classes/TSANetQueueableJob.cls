public class TSANetQueueableJob implements Queueable, Database.AllowsCallouts {
    
    public static Integer EXECUTE_LIMIT = 50;
    
    public static tsanet_connect__TSANetConfiguration__c CONFIG = tsanet_connect__TSANetConfiguration__c.getOrgDefaults();
    
    public Map<String, tsanet_connect__TSANetCase__c> cases = new Map<String, tsanet_connect__TSANetCase__c>();
    public Map<String, tsanet_connect__TSANetResponse__c> responses = new Map<String, tsanet_connect__TSANetResponse__c>();
    public Map<String, tsanet_connect__TSANetNote__c> notes = new Map<String, tsanet_connect__TSANetNote__c>();
    
    public String token;
        
    public Integer currentPage;
    public Integer totalPages;
    
    public TSANetQueueableJob(Integer currentPage,
                              Integer totalPages,
                              Map<String, tsanet_connect__TSANetCase__c> cases, 
                              Map<String, tsanet_connect__TSANetResponse__c> responses, 
                              Map<String, tsanet_connect__TSANetNote__c> notes){
                                  
        this.currentPage = currentPage;
        this.totalPages = totalPages != NULL ? totalPages : 1;
        this.cases = cases != NULL ? cases : new Map<String, tsanet_connect__TSANetCase__c>();
        this.responses = responses != NULL ? responses : new Map<String, tsanet_connect__TSANetResponse__c>();
        this.notes = notes != NULL ? notes : new Map<String, tsanet_connect__TSANetNote__c>();
        this.token = TSANetService.getTSANetAccessToken();
    }
    
    
    public void execute(QueueableContext qc) {
        System.debug('Start execution - Page: ' + this.currentPage + ' / ' + this.totalPages);

        Boolean stopProcessing = false;
        Integer count = 0;

        while (count < EXECUTE_LIMIT) {
            try {
                TSANetData data = getTSANetCollaborationCases(this.token, this.currentPage);
                System.debug('Page ' + currentPage + ' → cases: ' + data.cases.size());

                if (data.cases.isEmpty()) {
                    System.debug('Empty response. Stopping further processing.');
                    stopProcessing = true;
                    break;
                }

                for(tsanet_connect__TSANetCase__c caseRecord : data.cases){
                    this.cases.put(caseRecord.tsanet_connect__CaseToken__c, caseRecord);
                }
                for(tsanet_connect__TSANetResponse__c response : data.responses){
                    this.responses.put(response.tsanet_connect__tsaNetResponseId__c, response);
                }
                for(tsanet_connect__TSANetNote__c note : data.notes){
                    this.notes.put(note.tsanet_connect__Token__c, note);
                }

                currentPage++;
                count++;
            } catch (Exception e) {
                System.debug('Callout error on page ' + currentPage + ' : ' + e.getMessage());
                stopProcessing = true;
                break;
            }
        }
        
        System.debug('stopProcessing : ' + stopProcessing);

        if (!stopProcessing && !Test.isRunningTest()) {
            System.debug('Queueing next batch. CurrentPage: ' + currentPage);
            System.enqueueJob(new TSANetQueueableJob(currentPage, totalPages, cases, responses, notes));
        } else {
            System.debug('Final step: Upserting data');
            System.debug('CASES: ' + cases.values().size());
            System.debug('RESPONSES: ' + responses.values().size());
            System.debug('NOTES: ' + notes.values().size());
            
            Database.UpsertResult[] tsaNetCaseResult = Database.upsert(cases.values(), tsanet_connect__TSANetCase__c.tsanet_connect__CaseToken__c, false);
            Database.UpsertResult[] tsaNetResponseResult = Database.upsert(responses.values(), tsanet_connect__TSANetResponse__c.tsanet_connect__tsaNetResponseId__c, false);
            Database.UpsertResult[] tsaNetNoteResult = Database.upsert(notes.values(), tsanet_connect__TSANetNote__c.tsanet_connect__Token__c, false);
            
            tsanet_connect__TSANetError__c[] errors = new tsanet_connect__TSANetError__c[]{};
    
            errors.addAll(ErrorManager.collectErrors(tsaNetCaseResult, cases.values(), tsanet_connect__TSANetCase__c.tsanet_connect__CaseToken__c));
            errors.addAll(ErrorManager.collectErrors(tsaNetNoteResult, notes.values(), tsanet_connect__TSANetNote__c.tsanet_connect__Token__c));
            errors.addAll(ErrorManager.collectErrors(tsaNetResponseResult, responses.values(), tsanet_connect__TSANetResponse__c.tsanet_connect__tsaNetResponseId__c));
            
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
        System.debug('BODYYYY : ' + res.getBody());
        
        TSANetCaseDataResponse data = TSANetCaseDataResponse.parse(res.getBody());
        
        System.debug(data.totalPages);

		this.totalPages = data.totalPages;
        
        return ParserManager.parseTSANetCases(System.JSON.serialize(data.content), null);
    }
    
    
}