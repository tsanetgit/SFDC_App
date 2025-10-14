@isTest
public class TSANetInvocableApproveRequestServiceTest {

    @testSetup static void testSetup() {
        
        tsanet_connect__TSANetConfiguration__c config = tsanet_connect__TSANetConfiguration__c.getOrgDefaults();
        config.tsanet_connect__IntegrationUser__c = UserInfo.getUserId();
        upsert config;
        
        tsanet_connect__TSANet_Credentials__c credentials = new tsanet_connect__TSANet_Credentials__c();
        credentials.tsanet_connect__UserName__c = 'username@gmail.com';
        credentials.tsanet_connect__Password__c = 'password111';
        credentials.tsanet_connect__Environment__c = 'dev';
        credentials.tsanet_connect__Token__c = 'token';
        credentials.tsanet_connect__isPrimary__c = true;
        insert credentials;
        
        Account account = new Account(Name = 'Test Account');
        insert account;
        
        Contact contact = new Contact(LastName = 'Test Contact', Email = 'test@gmail.com', Phone = 'Test Phone', accountId = account.Id);
        insert contact;
        
        Case caseRecord = new Case(
            ContactId = contact.Id,
            AccountId = account.Id,
            Subject = 'test',
            Status = 'Working',
            Origin = 'Phone');
        
        insert caseRecord;
        
        tsanet_connect__TSANetCase__c tsaNetCase = new tsanet_connect__TSANetCase__c(tsanet_connect__Token__c = 'test-token', tsanet_connect__CaseToken__c='test-token', tsanet_connect__Case__c = caseRecord.Id);
        insert tsaNetCase;
	}
    
    @isTest
    public static void approveCollaborationRequestTest(){
        String body = '{ "documentId": 2115, "internalCaseNumber": "", "optionalRecieverInternalCaseNumber": "", "problemSummary": "", "problemDescription": "", "casePriority": "", "readonlyAdminNote": "<p>test admin note (description)</p>", "readonlyEscalationInstructions": "<p>test escalation instructions</p>", "testSubmission": false, "customerData": [ { "id": 5558, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Company", "value": null }, { "id": 5559, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Name", "value": null }, { "id": 5560, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Email", "value": null }, { "id": 5561, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Phone Including Country Code", "value": null }, { "id": 5562, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Case # with Connect2 Test 01 (Optional)", "value": null } ] }';
    	Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, body, null));
        Test.startTest();
            tsanet_connect__TSANetCase__c caseRecord = [SELECT Id, Name, tsanet_connect__Token__c FROM tsanet_connect__TSANetCase__c LIMIT 1];
            TSANetInvocableApproveRequestService.TSANetInput input = new TSANetInvocableApproveRequestService.TSANetInput();
            input.caseRecord = caseRecord;
            input.request = new TSANetCaseRequest();
            TSANetInvocableApproveRequestService.approveCollaborationRequest(new TSANetInvocableApproveRequestService.TSANetInput[]{ input });
            TSANetInvocableApproveRequestService.TSANetInvocableApproveRequestResult[] data = TSANetInvocableApproveRequestService.approveCollaborationRequest(new TSANetInvocableApproveRequestService.TSANetInput[]{ input });
            //System.assertEquals(true, data[0].caseRecord != NULL);
        Test.stopTest();
        
    }
    
    @isTest
    public static void approveAndUpdateToken(){
        String body = '{ "accessToken": "test.eyJpc3MiOiJodHRwOi8vY29ubmVjdDEucmVub2xhYi51cy9hcGkvYXV0aC9sb2dpbiIsImlhdCI6MTcyMDc3ODk0MiwiZXhwIjoxNzIwNzgyNTQyLCJuYmYiOjE3MjA3Nzg5NDIsImp0aSI6ImJrcDBGZ0k4T2ViNXdxU28iLCJzdWIiOiI4NzA1IiwicHJ2IjoiODdlMGFmMWVmOWZkMTU4MTJmZGVjOTcxNTNhMTRlMGIwNDc1NDZhYSJ9.YbmRLRwdzcua0lh3mCawfb7dvx5LQqJwrboZG4wGFEo", "tokenType": "bearer", "expiresIn": 3600 }';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, body, null));        
        Test.startTest();
            tsanet_connect__TSANetCase__c caseRecord = [SELECT Id, Name, tsanet_connect__Token__c, tsanet_connect__CaseToken__c FROM tsanet_connect__TSANetCase__c LIMIT 1];
            TSANetInvocableApproveRequestService.TSANetInput input = new TSANetInvocableApproveRequestService.TSANetInput();
            input.caseRecord = caseRecord;
            input.request = new TSANetCaseRequest();
            TSANetInvocableApproveRequestService.approveAndUpdateToken(input);
        Test.stopTest();
    }
}