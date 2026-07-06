/** Invocable service that accepts an incoming TSANet collaboration request. */
global with sharing class TSANetInvocableApproveRequestService {

    /** @deprecated Credentials are now resolved internally by TSANetService. */
    @Deprecated
    global static tsanetconnect__TSANet_Credentials__c credential;

    /** Input wrapper for the approve-request invocable action. */
    global class TSANetInput {
        /** The TSANet case record to approve. */
        @InvocableVariable
        global tsanetconnect__TSANetCase__c caseRecord;
        /** The approval form data to send to TSANet. */
        @InvocableVariable
        global TSANetApprovalForm request;
        /** When true, runs the approval in a @Future context. */
        @InvocableVariable
        global Boolean runAsync;
    }

    /** Result wrapper returned by the approve-request invocable action. */
	global class TSANetAcceptRequestResult {
        /** Indicates whether the approval succeeded. */
        @InvocableVariable
        global Boolean isSuccess;
        /** Descriptive message about the outcome. */
        @InvocableVariable
        global String message;
    }

    /**
     * Approves an incoming TSANet collaboration request.
     * @param inputs list of TSANetInput containing the case and approval form
     * @return list of TSANetAcceptRequestResult with success flag and message
     */
    @InvocableMethod(label='TSANet Accept Collaboration Request' description='Returns: isSuccess: boolean, message: string' category='TSANet')
    global static TSANetAcceptRequestResult[] approveCollaborationRequest(TSANetInput[] inputs) {

        TSANetAcceptRequestResult result = new TSANetAcceptRequestResult();

        TSANetInput input = inputs[0];

        String json = System.JSON.serialize(input.request);
        String caseToken = input.caseRecord.tsanetconnect__Token__c;

        if (input.runAsync == true) {
            approveAsync(caseToken, json);
            result.message = 'The collaboration request approval has been queued';
            result.isSuccess = true;
            return new TSANetAcceptRequestResult[]{ result };
        }

        try {
            TSANetService.approveIncomingRequest(caseToken, json, null);
            result.message = 'The collaboration request has been accepted successfully';
            result.isSuccess = true;
            return new TSANetAcceptRequestResult[]{ result };
        } catch(Exception e){
            result.message = e.getMessage();
            result.isSuccess = false;
            return new TSANetAcceptRequestResult[]{ result };
        }
    }

    /** Runs the approval callout asynchronously. */
    @Future(callout=true)
    public static void approveAsync(String caseToken, String json) {
        try {
            TSANetService.approveIncomingRequest(caseToken, json, null);
        } catch(Exception e) {
            ErrorLogger.logError(e, 'TSANET_APPROVE_ASYNC');
        }
    }
}
