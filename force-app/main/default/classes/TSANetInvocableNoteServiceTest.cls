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
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, body, null));
        Test.startTest();
            tsanetconnect__TSANetCase__c caseRecord = [SELECT Id, tsanetconnect__tsaNetCaseId__c, tsanetconnect__Token__c FROM tsanetconnect__TSANetCase__c LIMIT 1];
            TSANetInvocableNoteService.TSANetInput input = new TSANetInvocableNoteService.TSANetInput();
            TSANetNoteForm note = new TSANetNoteForm();
            input.caseRecord = caseRecord;
            input.note = note;

            TSANetInvocableNoteService.createNote(new TSANetInvocableNoteService.TSANetInput[]{ input });
        Test.stopTest();
    }
}