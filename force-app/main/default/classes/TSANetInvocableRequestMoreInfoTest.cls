@isTest
public class TSANetInvocableRequestMoreInfoTest {

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
    public static void rejectCollaborationRequestTest(){
        String body = '{ "documentId": 2115, "internalCaseNumber": "", "optionalRecieverInternalCaseNumber": "", "problemSummary": "", "problemDescription": "", "casePriority": "", "readonlyAdminNote": "<p>test admin note (description)</p>", "readonlyEscalationInstructions": "<p>test escalation instructions</p>", "testSubmission": false, "customerData": [ { "id": 5558, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Company", "value": null }, { "id": 5559, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Name", "value": null }, { "id": 5560, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Email", "value": null }, { "id": 5561, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Phone Including Country Code", "value": null }, { "id": 5562, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Case # with Connect2 Test 01 (Optional)", "value": null } ] }';
    	Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, body, null));
        Test.startTest();
            tsanetconnect__TSANetCase__c caseRecord = [SELECT Id, Name, tsanetconnect__Token__c FROM tsanetconnect__TSANetCase__c LIMIT 1];
            TSANetInvocableRequestMoreInformation.TSANetInput input = new TSANetInvocableRequestMoreInformation.TSANetInput();
            input.caseRecord = caseRecord;
            input.form = new TSANetRequestInfoForm();
            TSANetInvocableRequestMoreInformation.TSANetRequestResult[] data = TSANetInvocableRequestMoreInformation.requestMoreInformation(new TSANetInvocableRequestMoreInformation.TSANetInput[]{ input });
        Test.stopTest();
        
    }
}