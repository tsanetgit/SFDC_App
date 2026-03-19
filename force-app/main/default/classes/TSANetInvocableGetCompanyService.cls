global class TSANetInvocableGetCompanyService {

    global static tsanetconnect__TSANet_Credentials__c credential = CredentialManager.getCredentials();
    
    global  class TSANetCompanyResult {
        @InvocableVariable 
        global  TSANetCompanyOption[] companies;
    }
    
    @InvocableMethod(label='Get TSANet Companies' description='Returns the list of TSANet Companies' category='TSANet')
    global static TSANetCompanyResult[] getCompanies(String[] companyName) {
        String name = companyName[0];
        String body = TSANetService.getCompaniesByName(name, null);

        TSANetCompanyResult result = new TSANetCompanyResult();
        TSANetCompanyOption[] companies = (TSANetCompanyOption[]) System.JSON.deserialize(body, TSANetCompanyOption[].class);
        for(TSANetCompanyOption company : companies){
            company.value = company.companyId != NULL ? String.valueOf(company.companyId) : String.valueOf(company.departmentId);
        }
        result.companies = companies;
        return new TSANetCompanyResult[]{ result };
    }
    
}