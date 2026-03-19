global without sharing class TSANetInvocableApproveRequestService {

    global static tsanetconnect__TSANet_Credentials__c credential = CredentialManager.getCredentials();
    
    global class TSANetInput {
        @InvocableVariable 
        global tsanetconnect__TSANetCase__c caseRecord;
        @InvocableVariable 
        global TSANetApprovalForm request;
    }
    
	global class TSANetAcceptRequestResult {
        @InvocableVariable 
        global Boolean isSuccess;
        @InvocableVariable 
        global String message;
    }
    
    @InvocableMethod(label='TSANet Accept Collaboration Request' description='Returns: isSuccess: boolean, message: string' category='TSANet')
    global static TSANetAcceptRequestResult[] approveCollaborationRequest(TSANetInput[] inputs) {
        
        TSANetAcceptRequestResult result = new TSANetAcceptRequestResult();
        
        TSANetInput input = inputs[0];
        String body = System.JSON.serialize(input);
        
        String json = System.JSON.serialize(input.request);
        String caseToken = input.caseRecord.tsanetconnect__Token__c;
        
        try {
            String responseBody = TSANetService.approveIncomingRequest(caseToken, json, null);
            result.message = 'The collaboration request has been accepted successfully';
            result.isSuccess = true;
            return new TSANetAcceptRequestResult[]{ result };
        } catch(Exception e){
            result.message = e.getMessage();
            result.isSuccess = false;
            return new TSANetAcceptRequestResult[]{ result };
        }
    }
}