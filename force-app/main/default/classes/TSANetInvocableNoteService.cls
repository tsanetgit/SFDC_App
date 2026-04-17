/** Invocable service that creates a note on a TSANet collaboration case. */
global with sharing class TSANetInvocableNoteService {

    /** Input wrapper containing the TSANet case and note data. */
    global class TSANetInput {
        /** The TSANet case record to add the note to. */
        @InvocableVariable
        global tsanetconnect__TSANetCase__c caseRecord;
        /** The note form with content to submit. */
        @InvocableVariable
        global TSANetNoteForm note;
    }

    /** Result wrapper returned by the create-note invocable action. */
    global class TSANetNoteResult {
        /** Indicates whether the note creation succeeded. */
        @InvocableVariable
        global Boolean isSuccess;
        /** Descriptive message about the outcome. */
        @InvocableVariable
        global String message;
    }

    /**
     * Creates a note on the specified TSANet collaboration case.
     * @param data list of TSANetInput containing the case and note form
     * @return list of TSANetNoteResult with success flag and message
     */
    @InvocableMethod(label='Create TSANet Note' description='Returns: isSuccess: boolean, message: string' category='TSANet')
    global static TSANetNoteResult[] createNote(TSANetInput[] data) {

        TSANetNoteResult result = new TSANetNoteResult();

        TSANetInput input = data[0];

        String caseToken = input.caseRecord.tsanetconnect__Token__c;
        String json = System.JSON.serialize(input.note);

        try {
            TSANetService.createTSANetNote(caseToken, json, null);
            result.message = 'Note has been created successfully';
            result.isSuccess = true;
            return new TSANetNoteResult[]{ result };
        } catch(Exception e){
            result.message = e.getMessage();
            result.isSuccess = false;
            return new TSANetNoteResult[]{ result };
        }

    }
}