global class TSANetInvocableRequestMoreInformation  {

    global class TSANetInput {
        @InvocableVariable 
        global tsanetconnect__TSANetCase__c caseRecord;
        @InvocableVariable 
        global TSANetRequestInfoForm form;
    }
    
    global class TSANetRequestResult {
        @InvocableVariable 
        global Boolean isSuccess;
        @InvocableVariable 
        global String message;
    }

    @InvocableMethod(label='Request More Information' description='Returns: isSuccess: boolean, message: string' category='TSANet')
    global static TSANetRequestResult[] requestMoreInformation(TSANetInput[] data) {
        
        TSANetRequestResult result = new TSANetRequestResult();
        
        TSANetInput input = data[0];
        String json = JSON.serialize(input.form);
        
        try {
            String responseBody = TSANetService.requestAdditionalInformation(input.caseRecord.Id, json, null);
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