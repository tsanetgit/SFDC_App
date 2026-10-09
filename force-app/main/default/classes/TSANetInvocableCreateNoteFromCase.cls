/** Invocable action that finds a TSANet case by Salesforce Case Id and starts Create Note Automation. */
global with sharing class TSANetInvocableCreateNoteFromCase {

    private static final String FLOW_API_NAME = 'TSANetCreateNoteAutomation';

    /** Input wrapper containing the Salesforce Case Id. */
    global class TSANetInput {
        /** Salesforce Case Id used to locate the linked TSANetCase__c. */
        @InvocableVariable(required=true)
        global Id caseId;
    }

    /** Result wrapper returned by the create-test-note invocable action. */
    global class TSANetResult {
        /** Indicates whether the note creation flow succeeded. */
        @InvocableVariable
        global Boolean isSuccess;
        /** Descriptive message about the outcome. */
        @InvocableVariable
        global String message;
        /** Id of the TSANetCase__c used for the note, when found. */
        @InvocableVariable
        global Id tsaNetCaseId;
    }

    /**
     * Looks up the first TSANetCase__c for each Case Id and starts TSANetCreateNoteAutomation with a test note.
     * @param inputs list of TSANetInput containing Salesforce Case Ids
     * @return list of TSANetResult with success flag, message, and TSANet case Id
     */
    @InvocableMethod(
        label='Create TSANet Test Note From Case'
        description='Finds TSANetCase__c by Case Id and runs Create Note Automation with a Test Note'
        category='TSANet'
    )
    global static TSANetResult[] createTestNote(TSANetInput[] inputs) {
        List<TSANetResult> results = new List<TSANetResult>();
        if (inputs == null || inputs.isEmpty()) {
            return results;
        }

        Map<Id, Id> caseIdToTsaNetCaseId = mapFirstTsaNetCaseIds(inputs);

        for (TSANetInput input : inputs) {
            results.add(processInput(input, caseIdToTsaNetCaseId));
        }
        return results;
    }

    /** Builds Case Id -> first matching TSANetCase__c Id for the batch. */
    private static Map<Id, Id> mapFirstTsaNetCaseIds(TSANetInput[] inputs) {
        Set<Id> caseIds = new Set<Id>();
        for (TSANetInput input : inputs) {
            if (input != null && input.caseId != null) {
                caseIds.add(input.caseId);
            }
        }

        Map<Id, Id> caseIdToTsaNetCaseId = new Map<Id, Id>();
        if (caseIds.isEmpty()) {
            return caseIdToTsaNetCaseId;
        }

        for (tsanetconnect__TSANetCase__c tsaNetCase : [
            SELECT Id, tsanetconnect__Case__c
            FROM tsanetconnect__TSANetCase__c
            WHERE tsanetconnect__Case__c IN :caseIds
            AND tsanetconnect__Status__c = 'ACCEPTED'
            WITH USER_MODE
        ]) {
            if (!caseIdToTsaNetCaseId.containsKey(tsaNetCase.tsanetconnect__Case__c)) {
                caseIdToTsaNetCaseId.put(tsaNetCase.tsanetconnect__Case__c, tsaNetCase.Id);
            }
        }
        return caseIdToTsaNetCaseId;
    }

    /** Processes one invocable input: lookup + Flow.Interview start. */
    private static TSANetResult processInput(TSANetInput input, Map<Id, Id> caseIdToTsaNetCaseId) {
        TSANetResult result = new TSANetResult();

        if (input == null || input.caseId == null) {
            result.isSuccess = false;
            result.message = 'Case Id is required';
            return result;
        }

        Id tsaNetCaseId = caseIdToTsaNetCaseId.get(input.caseId);
        if (tsaNetCaseId == null) {
            result.isSuccess = false;
            result.message = 'No TSANet Case found for Case Id: ' + input.caseId;
            return result;
        }

        result.tsaNetCaseId = tsaNetCaseId;
        try {
            String testNote = buildUniqueTestNote();
            Map<String, Object> flowInputs = new Map<String, Object>{
                'recordId' => String.valueOf(tsaNetCaseId),
                'Description' => testNote,
                'Summary' => testNote
            };
            Flow.Interview interview = startCreateNoteFlow(flowInputs);
            Boolean flowSuccess = (Boolean) interview.getVariableValue('isSuccess');
            String flowMessage = (String) interview.getVariableValue('message');
            result.isSuccess = flowSuccess == true;
            result.message = String.isNotBlank(flowMessage)
                ? flowMessage
                : (result.isSuccess ? 'Note has been created successfully' : 'Flow completed without success');
        } catch (Exception e) {
            result.isSuccess = false;
            result.message = e.getMessage();
        }
        return result;
    }

    /** Builds a unique test note text using the current datetime. */
    private static String buildUniqueTestNote() {
        return 'Test Note ' + Datetime.now().formatGmt('yyyy-MM-dd HH:mm:ss.SSS');
    }

    /** Starts TSANetCreateNoteAutomation with namespace when running in the package. */
    private static Flow.Interview startCreateNoteFlow(Map<String, Object> flowInputs) {
        String className = TSANetInvocableCreateNoteFromCase.class.getName();
        String namespace = className.contains('.') ? className.substringBefore('.') : null;

        Flow.Interview interview = String.isNotBlank(namespace)
            ? Flow.Interview.createInterview(namespace, FLOW_API_NAME, flowInputs)
            : Flow.Interview.createInterview(FLOW_API_NAME, flowInputs);
        interview.start();
        return interview;
    }
}
