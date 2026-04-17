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
     * @return list of TSANetRequestResult with success flag and message
     */
    @InvocableMethod(label='Request More Information' description='Returns: isSuccess: boolean, message: string' category='TSANet')
    global static TSANetRequestResult[] requestMoreInformation(TSANetInput[] data) {

        TSANetRequestResult result = new TSANetRequestResult();

        TSANetInput input = data[0];
        String json = JSON.serialize(input.form);

        try {
            TSANetService.requestAdditionalInformation(input.caseRecord.Id, json, null);
            result.message = 'The request for additional information has been sent successfully';
            result.isSuccess = true;
            return new TSANetRequestResult[]{ result };
        } catch(Exception e){
            result.message = e.getMessage();
            result.isSuccess = false;
            return new TSANetRequestResult[]{ result };
        }
    }
}