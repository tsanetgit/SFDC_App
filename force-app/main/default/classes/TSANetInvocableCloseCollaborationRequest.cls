/** Invocable service that closes an existing TSANet collaboration request. */
global with sharing class TSANetInvocableCloseCollaborationRequest {

    /** Input wrapper containing the TSANet case to close. */
    global class TSANetInput {
        /** The TSANet case record to close. */
        @InvocableVariable
        global tsanetconnect__TSANetCase__c caseRecord;
    }

    /** Result wrapper returned by the close-collaboration invocable action. */
    global class TSANetCloseResult {
        /** Indicates whether the close operation succeeded. */
        @InvocableVariable
        global Boolean isSuccess;
        /** Descriptive message about the outcome. */
        @InvocableVariable
        global String message;
    }

    /**
     * Closes the specified TSANet collaboration case.
     * @param data list of TSANetInput containing the case record to close
     * @return list of TSANetCloseResult with success flag and message
     */
    @InvocableMethod(label='Close TSANet Collaboration Request' description='Returns: isSuccess: boolean, message: string' category='TSANet')
    global static TSANetCloseResult[] closeCollaborationCase(TSANetInput[] data) {

        TSANetCloseResult result = new TSANetCloseResult();

        TSANetInput input = data[0];

        try {
            TSANetService.closeTSANetCase(input.caseRecord.Id, null);
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