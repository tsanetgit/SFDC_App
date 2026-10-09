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
     * @return one result per input, in the same order
     */
    @InvocableMethod(label='Get TSANet Companies' description='Returns the list of TSANet Companies' category='TSANet')
    global static TSANetCompanyResult[] getCompanies(String[] companyName) {
        TSANetCompanyResult[] results = new TSANetCompanyResult[]{};
        if (companyName == null) {
            return results;
        }

        for (String name : companyName) {
            TSANetCompanyResult result = new TSANetCompanyResult();
            try {
                String body = TSANetService.getCompaniesByName(name);
                TSANetCompanyOption[] companies = (TSANetCompanyOption[]) JSON.deserialize(body, TSANetCompanyOption[].class);
                if (companies != null) {
                    for (TSANetCompanyOption company : companies) {
                        company.value = company.companyId != NULL ? String.valueOf(company.companyId) : String.valueOf(company.departmentId);
                    }
                }
                result.companies = companies;
            } catch (Exception e) {
                result.companies = new TSANetCompanyOption[]{};
            }
            results.add(result);
        }
        return results;
    }

}
