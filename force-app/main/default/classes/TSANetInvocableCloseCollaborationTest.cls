@isTest
public class TSANetInvocableCloseCollaborationTest {

    @testSetup static void testSetup() {
        User user = TSANetDataFactory.createAdminUser();
        System.runAs(user){
            TSANetDataFactory.createCredentials();
            Account account = TSANetDataFactory.createAccount();
            Contact contact = TSANetDataFactory.createContact(account.Id);
            Case caseRecord = TSANetDataFactory.createCase(account.Id, contact.Id);
            TSANetDataFactory.createTSANetCase(caseRecord.Id);
        }
	}

    @isTest
    public static void closeRequestTest(){
        String body = '[ { "label": "Demo - VMware", "companyId": 1072, "departmentId": null } ]';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, body, null));
        TSANetInvocableCloseCollaborationRequest.TSANetInput input = new TSANetInvocableCloseCollaborationRequest.TSANetInput();
        tsanetconnect__TSANetCase__c caseRecord = [SELECT Id FROM tsanetconnect__TSANetCase__c LIMIT 1];
        input.caseRecord = caseRecord;
        Test.startTest();
        	TSANetInvocableCloseCollaborationRequest.TSANetCloseResult[] data = TSANetInvocableCloseCollaborationRequest.closeCollaborationCase(
                new TSANetInvocableCloseCollaborationRequest.TSANetInput[]{ input }
            );
        Test.stopTest();
    }
    
    @isTest
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
        	TSANetInvocableCloseCollaborationRequest.TSANetCloseResult[] data = TSANetInvocableCloseCollaborationRequest.closeCollaborationCase(
                new TSANetInvocableCloseCollaborationRequest.TSANetInput[]{ input }
            );
        Test.stopTest();
    }
}