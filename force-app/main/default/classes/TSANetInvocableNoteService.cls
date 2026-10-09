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
     * @return one result per input, in the same order
     */
    @InvocableMethod(label='Create TSANet Note' description='Returns: isSuccess: boolean, message: string' category='TSANet')
    global static TSANetNoteResult[] createNote(TSANetInput[] data) {
        TSANetNoteResult[] results = new TSANetNoteResult[]{};
        if (data == null) {
            return results;
        }

        for (TSANetInput input : data) {
            TSANetNoteResult result = new TSANetNoteResult();
            try {
                String caseToken = input.caseRecord.tsanetconnect__Token__c;
                applyCurrentUserAsSubmitter(input.note);
                TSANetService.createTSANetNote(caseToken, JSON.serialize(input.note, true));
                result.message = 'Note has been created successfully';
                result.isSuccess = true;
            } catch (Exception e) {
                result.message = e.getMessage();
                result.isSuccess = false;
            }
            results.add(result);
        }
        return results;
    }

    /** Notes are authored as the running user, not the Case Owner. */
    private static void applyCurrentUserAsSubmitter(TSANetNoteForm note){
        if(note == null){
            return;
        }
        if(note.submittedBy == null){
            note.submittedBy = new TSANetSubmittedBy();
        }
        note.submittedBy.firstName = UserInfo.getFirstName();
        note.submittedBy.lastName = UserInfo.getLastName();
    }
}
