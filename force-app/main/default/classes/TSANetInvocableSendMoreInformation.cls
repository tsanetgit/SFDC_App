/** Invocable service that sends additional information for a TSANet collaboration case. */
global with sharing class TSANetInvocableSendMoreInformation {

    /** Input wrapper containing the TSANet case and additional-info form. */
    global class TSANetInput {
        /** The TSANet case record to send additional information for. */
        @InvocableVariable
        global tsanetconnect__TSANetCase__c caseRecord;
        /** The form containing the additional information to send. */
        @InvocableVariable
        global TSANetRequestInfoForm form;
    }

    /** Result wrapper returned by the send-more-information invocable action. */
    global class TSANetSendInfoResult {
        /** Indicates whether the send operation succeeded. */
        @InvocableVariable
        global Boolean isSuccess;
        /** Descriptive message about the outcome. */
        @InvocableVariable
        global String message;
    }

    /**
     * Sends additional information for the specified TSANet collaboration case.
     * @param data list of TSANetInput containing the case and info form
     * @return one result per input, in the same order
     */
    @InvocableMethod(label='Send More Information' description='Returns: isSuccess: boolean, message: string' category='TSANet')
    global static TSANetSendInfoResult[] sendMoreInformation(TSANetInput[] data) {
        TSANetSendInfoResult[] results = new TSANetSendInfoResult[]{};
        if (data == null) {
            return results;
        }

        for (TSANetInput input : data) {
            TSANetSendInfoResult result = new TSANetSendInfoResult();
            try {
                TSANetService.sendAdditionalInformation(input.caseRecord.Id, JSON.serialize(input.form));
                result.message = 'The additional information has been sent successfully';
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
