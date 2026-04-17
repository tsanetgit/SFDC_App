/** Invocable service that rejects an incoming TSANet collaboration request. */
global with sharing class TSANetInvocableRejectCollaborationCase {

    /** Input wrapper containing the TSANet case and rejection form. */
    global class TSANetInput {
        /** The TSANet case record to reject. */
        @InvocableVariable
        global tsanetconnect__TSANetCase__c caseRecord;
        /** The rejection form with reason details. */
        @InvocableVariable
        global TSANetRejectForm form;
    }

    /** Result wrapper returned by the reject-collaboration invocable action. */
    global class TSANetRejectResult {
        /** Indicates whether the rejection succeeded. */
        @InvocableVariable
        global Boolean isSuccess;
        /** Descriptive message about the outcome. */
        @InvocableVariable
        global String message;
    }

    /**
     * Rejects the specified TSANet collaboration case with the provided reason.
     * @param data list of TSANetInput containing the case and rejection form
     * @return list of TSANetRejectResult with success flag and message
     */
    @InvocableMethod(label='Reject TSANet Collaboration Request' description='Returns: isSuccess: boolean, message: string' category='TSANet')
    global static TSANetRejectResult[] rejectCollaborationCase(TSANetInput[] data) {

        TSANetRejectResult result = new TSANetRejectResult();

        TSANetInput input = data[0];
        String json = JSON.serialize(input.form);

        try {
            TSANetService.rejectTSANetCase(input.caseRecord.Id, json, null);
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