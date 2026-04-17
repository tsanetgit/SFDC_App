/** Invocable service that retrieves a TSANet company collaboration form. */
global with sharing class TSANetInvocableGetFormService {

    /** Result wrapper containing the retrieved company form. */
    global class TSANetCompanyFormResult {
        /** The company form returned by TSANet. */
        @InvocableVariable
        global TSANetCompanyForm form;
    }

    /**
     * Retrieves the collaboration form for the specified TSANet company.
     * @param companyIds list containing the company Id to fetch the form for
     * @return list of TSANetCompanyFormResult with the company form
     */
    @InvocableMethod(label='Get Company Form' description='Returns company form' category='TSANet')
    global static TSANetCompanyFormResult[] getFormByCompanyId(String[] companyIds) {
        String companyId = companyIds[0];
        String body = TSANetService.getFormByCompanyId(companyId, 'company', null);

        TSANetCompanyFormResult result = new TSANetCompanyFormResult();
        result.form = (TSANetCompanyForm) System.JSON.deserialize(body, TSANetCompanyForm.class);
        return new TSANetCompanyFormResult[]{ result };
    }

}