@IsTest
public class TSANetInvocableApproveRequestServiceTest {

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
    public static void approveCollaborationRequestTest(){
        String body = '{ "documentId": 2115, "internalCaseNumber": "", "optionalRecieverInternalCaseNumber": "", "problemSummary": "", "problemDescription": "", "casePriority": "", "readonlyAdminNote": "<p>test admin note (description)</p>", "readonlyEscalationInstructions": "<p>test escalation instructions</p>", "testSubmission": false, "customerData": [ { "id": 5558, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Company", "value": null }, { "id": 5559, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Name", "value": null }, { "id": 5560, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Email", "value": null }, { "id": 5561, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Phone Including Country Code", "value": null }, { "id": 5562, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Case # with Connect2 Test 01 (Optional)", "value": null } ] }';
    	Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, body, null));
        Test.startTest();
            tsanetconnect__TSANetCase__c caseRecord = [SELECT Id, Name, tsanetconnect__Token__c FROM tsanetconnect__TSANetCase__c WITH USER_MODE LIMIT 1];
            TSANetInvocableApproveRequestService.TSANetInput input = new TSANetInvocableApproveRequestService.TSANetInput();
            input.caseRecord = caseRecord;
            input.request = new TSANetApprovalForm();
            TSANetInvocableApproveRequestService.TSANetAcceptRequestResult[] results =
                TSANetInvocableApproveRequestService.approveCollaborationRequest(new TSANetInvocableApproveRequestService.TSANetInput[]{ input });
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Expected one result per input');
        System.assertEquals(true, results[0].isSuccess, 'Approval should succeed: ' + results[0].message);

    }
}