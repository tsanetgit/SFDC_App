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
     * @return one result per input, in the same order
     */
    @InvocableMethod(label='Create TSANet Collaboration Case' description='Returns collaboration case' category='TSANet')
    global static TSANetCollaborationCaseResult[] createCollaborationCase(TSANetInput[] data) {
        TSANetCollaborationCaseResult[] results = new TSANetCollaborationCaseResult[]{};
        if (data == null) {
            return results;
        }

        for (TSANetInput input : data) {
            TSANetCollaborationCaseResult result = new TSANetCollaborationCaseResult();
            try {
                String body = TSANetService.createCollaborationCase(input.caseRecord.Id, JSON.serialize(input.form));
                TSANetUtils.futureRefresh(input.caseRecord.Id);
                result.caseRecord = (TSANetCollaborationCase) JSON.deserialize(body, TSANetCollaborationCase.class);
            } catch (Exception e) {
                // Leave caseRecord null so Flow can branch on it.
            }
            results.add(result);
        }
        return results;
    }

}
