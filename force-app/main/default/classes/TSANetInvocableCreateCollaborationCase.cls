/** Invocable service that creates a new TSANet collaboration case from a Salesforce Case. */
global with sharing class TSANetInvocableCreateCollaborationCase {

    /** Input wrapper containing the Salesforce Case and company form for collaboration. */
    global class TSANetInput {
        /** The Salesforce Case to create a collaboration request for. */
        @InvocableVariable
        global Case caseRecord;
        /** The company form with details for the collaboration request. */
        @InvocableVariable
        global TSANetCompanyForm form;
    }

    /** Result wrapper containing the created TSANet collaboration case. */
    global class TSANetCollaborationCaseResult {
        /** The collaboration case returned by TSANet after creation. */
        @InvocableVariable
        global TSANetCollaborationCase caseRecord;
    }

    /**
     * Creates a collaboration case in TSANet for the given Salesforce Case and form data.
     * @param data list of TSANetInput containing the case and form
     * @return list of TSANetCollaborationCaseResult with the created collaboration case
     */
    @InvocableMethod(label='Create TSANet Collaboration Case' description='Returns collaboration case' category='TSANet')
    global static TSANetCollaborationCaseResult[] createCollaborationCase(TSANetInput[] data) {
        TSANetInput input = data[0];
        String json = JSON.serialize(input.form);

        String body = TSANetService.createCollaborationCase(input.caseRecord.Id, json, null);

        if(!Test.isRunningTest()){ TSANetUtils.futureRefresh(input.caseRecord.Id); }

        TSANetCollaborationCaseResult result = new TSANetCollaborationCaseResult();
        result.caseRecord = (TSANetCollaborationCase) System.JSON.deserialize(body, TSANetCollaborationCase.class);
        return new TSANetCollaborationCaseResult[]{ result };
    }

}