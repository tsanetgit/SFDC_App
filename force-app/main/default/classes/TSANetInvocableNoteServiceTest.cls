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