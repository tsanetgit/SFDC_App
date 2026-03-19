global class TSANetInvocableGetFormService {
    
    global class TSANetCompanyFormResult {
        @InvocableVariable 
        global TSANetCompanyForm form;
    }
    
    @InvocableMethod(label='Get Company Form' description='Returns company form' category='TSANet')
    global static TSANetCompanyFormResult[] getFormByCompanyId(String[] companyIds) {
        String companyId = companyIds[0];
        String body = TSANetService.getFormByCompanyId(companyId, 'company', null);
        
        TSANetCompanyFormResult result = new TSANetCompanyFormResult();
        result.form = (TSANetCompanyForm) System.JSON.deserialize(body, TSANetCompanyForm.class);
        return new TSANetCompanyFormResult[]{ result };
    }

}