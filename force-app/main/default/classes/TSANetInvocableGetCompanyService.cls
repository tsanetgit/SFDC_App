/** Invocable service that retrieves TSANet companies by name. */
global with sharing class TSANetInvocableGetCompanyService {

    /** @deprecated Credentials are now resolved internally by TSANetService. */
    @Deprecated
    global static tsanetconnect__TSANet_Credentials__c credential;

    /** Result wrapper containing the list of matching TSANet companies. */
    global  class TSANetCompanyResult {
        /** List of company options matching the search criteria. */
        @InvocableVariable
        global  TSANetCompanyOption[] companies;
    }

    /**
     * Searches for TSANet companies whose name matches the provided value.
     * @param companyName list containing the company name to search for
     * @return list of TSANetCompanyResult with matching companies
     */
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