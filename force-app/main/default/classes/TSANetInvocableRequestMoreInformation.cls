/** Invocable service that requests additional information on a TSANet collaboration case. */
global with sharing class TSANetInvocableRequestMoreInformation  {

    /** Input wrapper containing the TSANet case and request-info form. */
    global class TSANetInput {
        /** The TSANet case record to request more information for. */
        @InvocableVariable
        global tsanetconnect__TSANetCase__c caseRecord;
        /** The form specifying what additional information is needed. */
        @InvocableVariable
        global TSANetRequestInfoForm form;
        /** When true, runs the request in a @Future context (required from record-triggered flows). */
        @InvocableVariable
        global Boolean runAsync;
    }

    /** Result wrapper returned by the request-more-information invocable action. */
    global class TSANetRequestResult {
        /** Indicates whether the information request succeeded. */
        @InvocableVariable
        global Boolean isSuccess;
        /** Descriptive message about the outcome. */
        @InvocableVariable
        global String message;
    }

    /**
     * Sends a request for additional information on the specified TSANet collaboration case.
     * @param data list of TSANetInput containing the case and request-info form
     * @return one result per input, in the same order
     */
    @InvocableMethod(label='Request More Information' description='Returns: isSuccess: boolean, message: string' category='TSANet')
    global static TSANetRequestResult[] requestMoreInformation(TSANetInput[] data) {
        TSANetRequestResult[] results = new TSANetRequestResult[]{};
        if (data == null) {
            return results;
        }

        for (TSANetInput input : data) {
            results.add(requestOne(input));
        }
        return results;
    }

    /** Sends one information request, optionally via @Future. */
    private static TSANetRequestResult requestOne(TSANetInput input) {
        TSANetRequestResult result = new TSANetRequestResult();
        try {
            String json = JSON.serialize(input.form);
            Id tsaNetCaseId = input.caseRecord.Id;

            if (input.runAsync == true) {
                requestAsync(tsaNetCaseId, json);
                result.message = 'The request for additional information has been queued';
                result.isSuccess = true;
                return result;
            }

            TSANetService.requestAdditionalInformation(tsaNetCaseId, json);
            result.message = 'The request for additional information has been sent successfully';
            result.isSuccess = true;
        } catch (Exception e) {
            result.message = e.getMessage();
            result.isSuccess = false;
        }
        return result;
    }

    /** Runs the information-request callout asynchronously. */
    @Future(callout=true)
    public static void requestAsync(String tsaNetCaseId, String json) {
        try {
            TSANetService.requestAdditionalInformation(tsaNetCaseId, json);
        } catch (Exception e) {
            ErrorLogger.logError(e, 'TSANET_REQUEST_INFO_ASYNC');
        }
    }
}
