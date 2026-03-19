global class TSANetInvocableRejectCollaborationCase {

    global class TSANetInput {
        @InvocableVariable 
        global tsanetconnect__TSANetCase__c caseRecord;
        @InvocableVariable 
        global TSANetRejectForm form;
    }
    
    global class TSANetRejectResult {
        @InvocableVariable 
        global Boolean isSuccess;
        @InvocableVariable 
        global String message;
    }

    @InvocableMethod(label='Reject TSANet Collaboration Request' description='Returns: isSuccess: boolean, message: string' category='TSANet')
    global static TSANetRejectResult[] rejectCollaborationCase(TSANetInput[] data) {
        
        TSANetRejectResult result = new TSANetRejectResult();
        
        TSANetInput input = data[0];
        String json = JSON.serialize(input.form);
        
        try {
            String responseBody = TSANetService.rejectTSANetCase(input.caseRecord.Id, json, null);
            result.message = 'The collaboration request has been rejected successfully';
            result.isSuccess = true;
            return new TSANetRejectResult[]{ result };
        } catch(Exception e){
            result.message = e.getMessage();
            result.isSuccess = false;
            return new TSANetRejectResult[]{ result };
        }
    }
}