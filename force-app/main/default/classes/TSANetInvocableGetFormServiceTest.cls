@IsTest

public class TSANetInvocableGetFormServiceTest {

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
    public static void getFormByCompanyIdTest(){
        String body = '{ "documentId": 2115, "internalCaseNumber": "", "optionalRecieverInternalCaseNumber": "", "problemSummary": "", "problemDescription": "", "casePriority": "", "readonlyAdminNote": "<p>test admin note (description)</p>", "readonlyEscalationInstructions": "<p>test escalation instructions</p>", "testSubmission": false, "customerData": [ { "id": 5558, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Company", "value": null }, { "id": 5559, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Name", "value": null }, { "id": 5560, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Email", "value": null }, { "id": 5561, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Phone Including Country Code", "value": null }, { "id": 5562, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Case # with Connect2 Test 01 (Optional)", "value": null } ] }';
    	Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, body, null));
        Test.startTest();
        	TSANetInvocableGetFormService.TSANetCompanyFormResult[] data = TSANetInvocableGetFormService.getFormByCompanyId(new String[]{ '1070' });
        	System.assertEquals(true, data[0].form != NULL);
        Test.stopTest();
    }
}