global class TSANetInvocableCloseCollaborationRequest {

    global class TSANetInput {
        @InvocableVariable 
        global tsanetconnect__TSANetCase__c caseRecord;
    }
    
    global class TSANetCloseResult {
        @InvocableVariable 
        global Boolean isSuccess;
        @InvocableVariable 
        global String message;
    }

    @InvocableMethod(label='Close TSANet Collaboration Request' description='Returns: isSuccess: boolean, message: string' category='TSANet')
    global static TSANetCloseResult[] closeCollaborationCase(TSANetInput[] data) {
        
        TSANetCloseResult result = new TSANetCloseResult();
        
        TSANetInput input = data[0];
        
        try {
            String responseBody = TSANetService.closeTSANetCase(input.caseRecord.Id, null);
            result.message = 'The collaboration request has been closed successfully';
            result.isSuccess = true;
            return new TSANetCloseResult[]{ result };
        } catch(Exception e){
            result.message = e.getMessage();
            result.isSuccess = false;
            return new TSANetCloseResult[]{ result };
        }
    }
}