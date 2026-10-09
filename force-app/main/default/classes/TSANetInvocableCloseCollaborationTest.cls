@IsTest
public class TSANetInvocableCloseCollaborationTest {

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
    public static void closeRequestTest(){
        String body = '[ { "label": "Demo - VMware", "companyId": 1072, "departmentId": null } ]';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, body, null));
        TSANetInvocableCloseCollaborationRequest.TSANetInput input = new TSANetInvocableCloseCollaborationRequest.TSANetInput();
        tsanetconnect__TSANetCase__c caseRecord = [SELECT Id FROM tsanetconnect__TSANetCase__c LIMIT 1];
        input.caseRecord = caseRecord;
        Test.startTest();
        	TSANetInvocableCloseCollaborationRequest.TSANetCloseResult[] results =
                TSANetInvocableCloseCollaborationRequest.closeCollaborationCase(
                    new TSANetInvocableCloseCollaborationRequest.TSANetInput[]{ input }
                );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Expected one result per input');
        System.assertEquals(true, results[0].isSuccess, 'Close should succeed: ' + results[0].message);
    }

    @IsTest
    public static void closeRequestWithErrorTest(){
        String body = '[ { "label": "Demo - VMware", "companyId": 1072, "departmentId": null } ]';

        tsanetconnect__TSANet_Credentials__c creds = [SELECT Id FROM tsanetconnect__TSANet_Credentials__c LIMIT 1];
        creds.isPrimary__c = false;
        update creds;
        delete creds;
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, body, null));
        TSANetInvocableCloseCollaborationRequest.TSANetInput input = new TSANetInvocableCloseCollaborationRequest.TSANetInput();
        tsanetconnect__TSANetCase__c caseRecord = [SELECT Id FROM tsanetconnect__TSANetCase__c LIMIT 1];
        input.caseRecord = caseRecord;
        Test.startTest();
        	TSANetInvocableCloseCollaborationRequest.TSANetCloseResult[] results =
                TSANetInvocableCloseCollaborationRequest.closeCollaborationCase(
                    new TSANetInvocableCloseCollaborationRequest.TSANetInput[]{ input }
                );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'A failure must still return one result per input');
        System.assertEquals(false, results[0].isSuccess, 'Closing without credentials must fail');
        System.assertNotEquals(null, results[0].message, 'A failed result must explain why');
    }
}
