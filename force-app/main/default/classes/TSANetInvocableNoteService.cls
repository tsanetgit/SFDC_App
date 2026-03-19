global class TSANetInvocableNoteService {

    global class TSANetInput {
        @InvocableVariable 
        global tsanetconnect__TSANetCase__c caseRecord;
        @InvocableVariable 
        global TSANetNoteForm note;
    }
    
    global class TSANetNoteResult {
        @InvocableVariable 
        global Boolean isSuccess;
        @InvocableVariable 
        global String message;
    }

    @InvocableMethod(label='Create TSANet Note' description='Returns: isSuccess: boolean, message: string' category='TSANet')
    global static TSANetNoteResult[] createNote(TSANetInput[] data) {
        
        TSANetNoteResult result = new TSANetNoteResult();
        
        TSANetInput input = data[0];
                
        String caseToken = input.caseRecord.tsanetconnect__Token__c;
        String json = System.JSON.serialize(input.note);
        
        try {
            String responseBody = TSANetService.createTSANetNote(caseToken, json, null);
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