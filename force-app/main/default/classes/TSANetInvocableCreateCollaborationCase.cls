global class TSANetInvocableCreateCollaborationCase {
    
    global class TSANetInput {
        @InvocableVariable 
        global Case caseRecord;
        @InvocableVariable 
        global TSANetCompanyForm form;
    }
    
    global class TSANetCollaborationCaseResult {
        @InvocableVariable 
        global TSANetCollaborationCase caseRecord;
    }

    @InvocableMethod(label='Create TSANet Collaboration Case' description='Returns collaboration case' category='TSANet')
    global static TSANetCollaborationCaseResult[] createCollaborationCase(TSANetInput[] data) {
        TSANetInput input = data[0];
        String json = JSON.serialize(input.form);
        
        String body = TSANetService.createCollaborationCase(input.caseRecord.Id, json, null);
        
        if(!Test.isRunningTest()){ TSANetUtils.futureRefresh(input.caseRecord.Id); }
        
        TSANetCollaborationCaseResult result = new TSANetCollaborationCaseResult();
        result.caseRecord = (TSANetCollaborationCase) System.JSON.deserialize(body, TSANetCollaborationCase.class);
        return new TSANetCollaborationCaseResult[]{ result };
    }
    
}