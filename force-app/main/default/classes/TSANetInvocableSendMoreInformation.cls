global class TSANetInvocableSendMoreInformation {

    global class TSANetInput {
        @InvocableVariable 
        global tsanetconnect__TSANetCase__c caseRecord;
        @InvocableVariable 
        global TSANetRequestInfoForm form;
    }
    
    global class TSANetSendInfoResult {
        @InvocableVariable 
        global Boolean isSuccess;
        @InvocableVariable 
        global String message;
    }

    @InvocableMethod(label='Send More Information' description='Returns: isSuccess: boolean, message: string' category='TSANet')
    global static TSANetSendInfoResult[] sendMoreInformation(TSANetInput[] data) {
        
        TSANetSendInfoResult result = new TSANetSendInfoResult();
        
        
        TSANetInput input = data[0];
        String json = JSON.serialize(input.form);
        
        try {
            String responseBody = TSANetService.sendAdditionalInformation(input.caseRecord.Id, json, null);
            result.message = 'The additional information has been sent successfully';
            result.isSuccess = true;
            return new TSANetSendInfoResult[]{ result };
        } catch(Exception e){
            result.message = e.getMessage();
            result.isSuccess = false;
            return new TSANetSendInfoResult[]{ result };
        }
    }
}