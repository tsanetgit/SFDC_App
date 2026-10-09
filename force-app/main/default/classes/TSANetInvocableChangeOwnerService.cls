/** Invocable action that notifies TSANet when a Salesforce Case owner changes. */
global with sharing class TSANetInvocableChangeOwnerService {

    /** Input wrapper containing the TSANet case whose owner changed. */
    global class TSANetInput {
        /** The TSANet case record associated with the owner change. */
        @InvocableVariable
        global tsanetconnect__TSANetCase__c caseRecord;
    }

    /** Result wrapper returned by the change-owner invocable action. */
    global class TSANetChangeOwnerResult {
        /** Indicates whether the owner change notification succeeded. */
        @InvocableVariable
        global Boolean isSuccess;
        /** Descriptive message about the outcome. */
        @InvocableVariable
        global String message;
    }

    /**
     * Notifies TSANet about a Case owner change, routing to the appropriate API based on direction.
     * @param inputs list of TSANetInput containing the case record
     * @return one result per input, in the same order
     */
    @InvocableMethod(label='TSANet Change Owner' description='Notifies TSANet when the Salesforce Case owner changes' category='TSANet')
    global static TSANetChangeOwnerResult[] changeOwner(TSANetInput[] inputs) {
        TSANetChangeOwnerResult[] results = new TSANetChangeOwnerResult[]{};
        if (inputs == null) {
            return results;
        }

        for (TSANetInput input : inputs) {
            TSANetChangeOwnerResult result = new TSANetChangeOwnerResult();
            try {
                String direction = input.caseRecord.tsanetconnect__Direction__c;
                if (String.isNotBlank(direction) && direction.equalsIgnoreCase('inbound')) {
                    TSANetService.changeTSANetResponse(input.caseRecord.Id);
                } else {
                    TSANetService.changeTSANetOwner(input.caseRecord.Id);
                }
                result.isSuccess = true;
                result.message = 'Owner change request submitted successfully';
            } catch (Exception e) {
                result.isSuccess = false;
                result.message = e.getMessage();
            }
            results.add(result);
        }
        return results;
    }
}
