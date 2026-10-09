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
     * @return one result per input, in the same order
     */
    @InvocableMethod(label='Get Company Form' description='Returns company form' category='TSANet')
    global static TSANetCompanyFormResult[] getFormByCompanyId(String[] companyIds) {
        TSANetCompanyFormResult[] results = new TSANetCompanyFormResult[]{};
        if (companyIds == null) {
            return results;
        }

        for (String companyId : companyIds) {
            TSANetCompanyFormResult result = new TSANetCompanyFormResult();
            try {
                String body = TSANetService.getFormByCompanyId(companyId, 'company');
                result.form = (TSANetCompanyForm) JSON.deserialize(body, TSANetCompanyForm.class);
            } catch (Exception e) {
                // Leave form null so Flow can branch on it.
            }
            results.add(result);
        }
        return results;
    }

}
