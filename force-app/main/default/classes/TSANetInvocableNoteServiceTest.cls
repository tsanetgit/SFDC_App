@IsTest
public class TSANetInvocableNoteServiceTest {

	@TestSetup static void testSetup() {

        User user = TSANetDataFactory.createAdminUser();
        System.runAs(user){
            TSANetDataFactory.createCredentials();
            Account account = TSANetDataFactory.createAccount();
            Contact contact = TSANetDataFactory.createContact(account.Id);
            Case caseRecord = TSANetDataFactory.createCase(account.Id, contact.Id);
            TSANetDataFactory.createTSANetCase(caseRecord.Id);
        }
	}

    @IsTest
    public static void createCollaborationCaseNoteTest(){
        String body = '{ "id": 185, "caseId": 2743, "creatorUsername": null, "creatorEmail": "sue.test@vmware.com", "creatorName": "Sue Test", "summary": "Note FROM VMWare 2", "description": "<p>Note FROM VMWare 2</p>", "priority": "LOW", "status": "ENTERED", "token": "5lUX0KtielPKn2ExCk", "createdAt": "2024-08-16T14:34:22Z", "updatedAt": "2024-09-12T19:31:52Z" }';
        CapturingNoteMock mock = new CapturingNoteMock(body);
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
            tsanetconnect__TSANetCase__c caseRecord = [SELECT Id, tsanetconnect__tsaNetCaseId__c, tsanetconnect__Token__c FROM tsanetconnect__TSANetCase__c WITH USER_MODE LIMIT 1];
            TSANetInvocableNoteService.TSANetInput input = new TSANetInvocableNoteService.TSANetInput();
            TSANetNoteForm note = new TSANetNoteForm();
            note.type = 'partner';
            note.submittedBy = new TSANetSubmittedBy();
            note.submittedBy.firstName = 'Case';
            note.submittedBy.lastName = 'Owner';
            input.caseRecord = caseRecord;
            input.note = note;

            TSANetInvocableNoteService.TSANetNoteResult[] results =
                TSANetInvocableNoteService.createNote(new TSANetInvocableNoteService.TSANetInput[]{ input });
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Expected one result per input');
        System.assertEquals(true, results[0].isSuccess, 'Note creation should succeed: ' + results[0].message);

        Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(mock.lastBody);
        Map<String, Object> submittedBy = (Map<String, Object>) payload.get('submittedBy');
        System.assertEquals(UserInfo.getFirstName(), submittedBy.get('firstName'), 'Note must be sent as the current user');
        System.assertEquals(UserInfo.getLastName(), submittedBy.get('lastName'), 'Note must be sent as the current user');
        Map<String, Object> type = (Map<String, Object>) payload.get('type');
        System.assertEquals('partner', type.get('code'), 'Type must be sent as NoteTypeReferenceDTO { code }');
    }

    @IsTest
    static void bulkInputsPersistNotesInOneDml(){
        String body = '{ "id": 185, "caseId": 2743, "creatorName": "Sue Test", "summary": "Note", "description": "<p>Note</p>", "priority": "LOW", "status": "ENTERED", "token": "{token}", "createdAt": "2024-08-16T14:34:22Z", "updatedAt": "2024-09-12T19:31:52Z" }';
        // The sixth callout fails so the batch mixes successes with a failure.
        Test.setMock(HttpCalloutMock.class, new TokenizedNoteMock(body, 5));
        tsanetconnect__TSANetCase__c caseRecord = [SELECT Id, tsanetconnect__Token__c FROM tsanetconnect__TSANetCase__c WITH USER_MODE LIMIT 1];

        TSANetInvocableNoteService.TSANetInput[] inputs = new TSANetInvocableNoteService.TSANetInput[]{};
        for (Integer i = 0; i < 6; i++) {
            TSANetInvocableNoteService.TSANetInput input = new TSANetInvocableNoteService.TSANetInput();
            input.caseRecord = caseRecord;
            input.note = new TSANetNoteForm();
            inputs.add(input);
        }

        Test.startTest();
            Integer dmlBefore = Limits.getDmlStatements();
            TSANetInvocableNoteService.TSANetNoteResult[] results = TSANetInvocableNoteService.createNote(inputs);
            Integer dmlUsed = Limits.getDmlStatements() - dmlBefore;
        Test.stopTest();

        System.assertEquals(inputs.size(), results.size(), 'Expected one result per input, in order');
        System.assertEquals(1, dmlUsed, 'All notes must be upserted in a single DML after the callouts');
        for (Integer i = 0; i < 5; i++) {
            System.assertEquals(true, results[i].isSuccess, 'Valid input should succeed: ' + results[i].message);
        }
        System.assertEquals(false, results[5].isSuccess, 'A failed callout must fail its own input without aborting the batch');
        System.assertEquals(5, [SELECT COUNT() FROM tsanetconnect__TSANetNote__c], 'One note persisted per successful callout');
    }

    /**
     * Returns the response body with a unique token per request so each note upserts as a new row,
     * and throws on the configured call index to simulate one failed callout.
     */
    private class TokenizedNoteMock implements HttpCalloutMock {
        private String responseBody;
        private Integer failOnCall;
        private Integer calls = 0;

        TokenizedNoteMock(String responseBody, Integer failOnCall) {
            this.responseBody = responseBody;
            this.failOnCall = failOnCall;
        }

        public HTTPResponse respond(HTTPRequest req) {
            if (calls == failOnCall) {
                calls++;
                throw new CalloutException('Simulated TSANet outage');
            }
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(responseBody.replace('{token}', 'note-token-' + (calls++)));
            return res;
        }
    }

    /** Captures the outbound note JSON so tests can assert submittedBy. */
    private class CapturingNoteMock implements HttpCalloutMock {
        public String lastBody;
        private String responseBody;

        CapturingNoteMock(String responseBody) {
            this.responseBody = responseBody;
        }

        public HTTPResponse respond(HTTPRequest req) {
            if(String.isNotBlank(req.getBody())){
                this.lastBody = req.getBody();
            }
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(responseBody);
            return res;
        }
    }
}