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
     * @return one result per input, in the same order
     */
    @InvocableMethod(label='Close TSANet Collaboration Request' description='Returns: isSuccess: boolean, message: string' category='TSANet')
    global static TSANetCloseResult[] closeCollaborationCase(TSANetInput[] data) {
        TSANetCloseResult[] results = new TSANetCloseResult[]{};
        if (data == null) {
            return results;
        }

        for (TSANetInput input : data) {
            TSANetCloseResult result = new TSANetCloseResult();
            try {
                TSANetService.closeTSANetCase(input.caseRecord.Id);
                result.message = 'The collaboration request has been closed successfully';
                result.isSuccess = true;
            } catch (Exception e) {
                result.message = e.getMessage();
                result.isSuccess = false;
            }
            results.add(result);
        }
        return results;
    }
}
