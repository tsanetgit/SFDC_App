@isTest
public class TSANetServiceTest {
    
    @testSetup static void testSetup() {
        
        tsanet_connect__TSANetConfiguration__c config = tsanet_connect__TSANetConfiguration__c.getOrgDefaults();
        config.tsanet_connect__IntegrationUser__c = UserInfo.getUserId();
        upsert config;
        
        tsanet_connect__TSANet_Credentials__c credentials = new tsanet_connect__TSANet_Credentials__c();
        credentials.tsanet_connect__UserName__c = 'username@gmail.com';
        credentials.tsanet_connect__Password__c = 'password111';
        credentials.tsanet_connect__Token__c = 'token';
        credentials.tsanet_connect__isPrimary__c = true;
        credentials.tsanet_connect__Environment__c = 'dev';
        
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
        
        tsanet_connect__TSANetCase__c tsaNetCase = new tsanet_connect__TSANetCase__c(tsanet_connect__Token__c = 'test-token', tsanet_connect__CaseToken__c = 'test-token', tsanet_connect__Case__c = caseRecord.Id);
        insert tsaNetCase;
	}
    
    @isTest
    public static void getAccessTokenTest(){
        String body = '{ "accessToken": "test.eyJpc3MiOiJodHRwOi8vY29ubmVjdDEucmVub2xhYi51cy9hcGkvYXV0aC9sb2dpbiIsImlhdCI6MTcyMDc3ODk0MiwiZXhwIjoxNzIwNzgyNTQyLCJuYmYiOjE3MjA3Nzg5NDIsImp0aSI6ImJrcDBGZ0k4T2ViNXdxU28iLCJzdWIiOiI4NzA1IiwicHJ2IjoiODdlMGFmMWVmOWZkMTU4MTJmZGVjOTcxNTNhMTRlMGIwNDc1NDZhYSJ9.YbmRLRwdzcua0lh3mCawfb7dvx5LQqJwrboZG4wGFEo", "tokenType": "bearer", "expiresIn": 3600 }';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, body, null));
        Test.startTest();
        	//TSANetService.getAccessToken();
        Test.stopTest();
    }
    
    @isTest
    public static void getBearerTokenTest(){
        //TSANetService.getBearerToken();
    }
    
    @isTest
    public static void getRelatedCollaborationCasesTest(){
        String body = '[ { "id": 2718, "submitCompanyName": "Demo - VMware", "submitCompanyId": 1072, "submitterCaseNumber": "00001036", "receiveCompanyName": "Demo - Cisco", "receiveCompanyId": 1071, "receiverCaseNumber": "2718", "summary": "Beta Summer 2024 release unit test", "description": "Beta Summer 2024 release unit test", "priority": "LOW", "status": "ACCEPTED", "token": "Pp8DCQVVHkkVvd0rpn", "createdAt": "2024-06-19T17:17:00Z", "updatedAt": "2024-06-28T04:54:26Z", "deletedAt": null, "responded": true, "respondBy": "2024-06-20T17:17:00Z", "feedbackRequested": false, "reminderSent": false, "priorityNote": "<p>Priority 3 (24 Hours)</p>", "escalationInstructions": "test", "testCase": false, "customFields": [ { "id": 17465, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Company", "value": "Dickenson plc" }, { "id": 17466, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Name", "value": "sean jones" }, { "id": 17467, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Email", "value": "sean@bur.com" }, { "id": 17468, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Phone Including Country Code", "value": "4155551212" }, { "id": 17469, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Case # with Demo - Cisco (Optional)", "value": "9876" } ], "submittedBy": { "id": 8706, "username": null, "firstName": "Sue", "lastName": "Test", "email": "sue.test@vmware.com", "phone": "4155551212", "phoneCountryCode": "US", "city": "Baton Rouge" }, "caseNotes": [ { "id": 151, "caseId": 2718, "creatorUsername": null, "creatorEmail": "John.Smith@cisco.com", "summary": "new note", "description": "<p>testing</p>", "priority": "low", "status": "entered", "token": "HeRU7whkYdvVXS9Y8p", "createdAt": "2024-06-19T17:20:23Z", "updatedAt": "2024-06-19T17:20:24Z" }, { "id": 154, "caseId": 2718, "creatorUsername": null, "creatorEmail": "sue.test@vmware.com", "summary": "New note from Paul", "description": "<p>Testing</p>", "priority": "low", "status": "entered", "token": "RoI4TxVcrnirlKLxVNiK", "createdAt": "2024-06-28T04:54:25Z", "updatedAt": "2024-06-28T04:54:26Z" } ], "caseResponses": [ { "id": 2136, "type": "APPROVAL", "caseNumber": "2718", "engineerName": "John Smith", "engineerPhone": "+12122241255", "engineerEmail": "John.Smith@cisco.com", "nextSteps": "Our assigned engineer will contact you.", "createdAt": null } ] } ]';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, body, null));
        
        Test.startTest();
            Case caseRecord = [SELECT Id FROM Case LIMIT 1];
            TSANetService.getRelatedCollaborationCases(null, null);
        Test.stopTest();
    }
    
    @isTest
    public static void getRelatedCollaborationCasesBadTest(){
        String body = '{ "error": "message" }';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(400, body, null));
        
        Test.startTest();
        try {
            Case caseRecord = [SELECT Id FROM Case LIMIT 1];
            TSANetService.getRelatedCollaborationCases(caseRecord.Id, null);
        } catch(Exception e){
            System.assertEquals('{ "error": "message" }', e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest
    public static void getCompanyInfoTest(){
        String body2 = '{ "company": { "id": 1071, "name": "Demo - Cisco", "description": null }, "user": { "id": 8705, "username": null, "firstName": "John", "lastName": "Smith", "email": "John.Smith@cisco.com", "phone": "4155551212", "phoneCountryCode": "VG", "city": "Baton Rouge" }, "encodedCredentials": "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwOi8vY29ubmVjdDEucmVub2xhYi51cy9hcGkvYXV0aC9sb2dpbiIsImlhdCI6MTcyMDc3ODk0MiwiZXhwIjoxNzIwNzgyNTQyLCJuYmYiOjE3MjA3Nzg5NDIsImp0aSI6ImJrcDBGZ0k4T2ViNXdxU28iLCJzdWIiOiI4NzA1IiwicHJ2IjoiODdlMGFmMWVmOWZkMTU4MTJmZGVjOTcxNTNhMTRlMGIwNDc1NDZhYSJ9.YbmRLRwdzcua0lh3mCawfb7dvx5LQqJwrboZG4wGFEo" }';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, body2, null));
        Test.startTest();
        	TSANetService.getCompanyInformation(null);
        Test.stopTest();
    }
    
    @isTest
    public static void getFormByCompanyIdTest(){
        String body = '{ "documentId": 2115, "internalCaseNumber": "", "optionalRecieverInternalCaseNumber": "", "problemSummary": "", "problemDescription": "", "casePriority": "", "readonlyAdminNote": "<p>test admin note (description)</p>", "readonlyEscalationInstructions": "<p>test escalation instructions</p>", "testSubmission": false, "customerData": [ { "id": 5558, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Company", "value": null }, { "id": 5559, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Name", "value": null }, { "id": 5560, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Email", "value": null }, { "id": 5561, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Phone Including Country Code", "value": null }, { "id": 5562, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Case # with Connect2 Test 01 (Optional)", "value": null } ] }';
    	Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, body, null));
        Test.startTest();
        	TSANetService.getFormByCompanyId('1069', 'company', null);
        	TSANetService.getFormByCompanyId('1070', 'department', null);
        Test.stopTest();
    }
    
    @isTest
    public static void getCompaniesByNameTest(){
        String body = '[ { "label": "Demo - VMware", "companyId": 1072, "departmentId": null } ]';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, body, null));
        Test.startTest();
        	TSANetService.getCompaniesByName('Demo', null);
        Test.stopTest();
    }
    
    @isTest
    public static void createCollaborationCaseTest(){
        String body = '{"id":2735,"submitCompanyName":"Demo - Cisco","submitCompanyId":1071,"submitterCaseNumber":"00001008","receiveCompanyName":"Demo - VMware","receiveCompanyId":1072,"receiverCaseNumber":"","summary":"Customer service for portable generators needs beefing up","description":"test","priority":"LOW","status":"OPEN","token":"UNHd8HyqFB1cADcwOj","createdAt":"2024-07-16T16:15:10Z","updatedAt":null,"deletedAt":null,"responded":false,"respondBy":"2024-07-17T16:15:10Z","feedbackRequested":false,"reminderSent":false,"priorityNote":"<p>Priority 3 (24 Hours)</p>","escalationInstructions":"<p>test Vmware escalation</p>","testCase":false,"customFields":[{"id":17585,"section":"PROBLEM_SECTION","fieldName":"Product Area","value":"Cloud (Other Non-Platform Products):Authomize"},{"id":17577,"section":"COMMON_CUSTOMER_SECTION","fieldName":"Customer Company","value":"Grand Hotels & Resorts Ltd"},{"id":17578,"section":"COMMON_CUSTOMER_SECTION","fieldName":"Customer Name","value":"Tim Barr"},{"id":17579,"section":"COMMON_CUSTOMER_SECTION","fieldName":"Customer Email","value":"barr_tim@grandhotels.com"},{"id":17580,"section":"COMMON_CUSTOMER_SECTION","fieldName":"Customer Phone Including Country Code","value":"(312) 596-1000"},{"id":17581,"section":"COMMON_CUSTOMER_SECTION","fieldName":"Customer Case # with Demo - VMware (Optional)","value":""},{"id":17582,"section":"PROBLEM_SECTION","fieldName":"Version","value":"1"},{"id":17583,"section":"COMMON_CUSTOMER_SECTION","fieldName":"Serial Number","value":"1"},{"id":17584,"section":"COMMON_CUSTOMER_SECTION","fieldName":"Region","value":"Americas"}],"submittedBy":{"id":8705,"username":null,"firstName":"John","lastName":"Smith","email":"John.Smith@cisco.com","phone":"4155551212","phoneCountryCode":"VG","city":"Baton Rouge"},"caseNotes":[],"caseResponses":[]}';
        String json = '{"id":2735,"submitCompanyName":"Demo - Cisco","submitCompanyId":1071,"submitterCaseNumber":"00001008","receiveCompanyName":"Demo - VMware","receiveCompanyId":1072,"receiverCaseNumber":"","summary":"Customer service for portable generators needs beefing up","description":"test","priority":"LOW","status":"OPEN","token":"UNHd8HyqFB1cADcwOj","createdAt":"2024-07-16T16:15:10Z","updatedAt":null,"deletedAt":null,"responded":false,"respondBy":"2024-07-17T16:15:10Z","feedbackRequested":false,"reminderSent":false,"priorityNote":"<p>Priority 3 (24 Hours)</p>","escalationInstructions":"<p>test Vmware escalation</p>","testCase":false,"customFields":[{"id":17585,"section":"PROBLEM_SECTION","fieldName":"Product Area","value":"Cloud (Other Non-Platform Products):Authomize"},{"id":17577,"section":"COMMON_CUSTOMER_SECTION","fieldName":"Customer Company","value":"Grand Hotels & Resorts Ltd"},{"id":17578,"section":"COMMON_CUSTOMER_SECTION","fieldName":"Customer Name","value":"Tim Barr"},{"id":17579,"section":"COMMON_CUSTOMER_SECTION","fieldName":"Customer Email","value":"barr_tim@grandhotels.com"},{"id":17580,"section":"COMMON_CUSTOMER_SECTION","fieldName":"Customer Phone Including Country Code","value":"(312) 596-1000"},{"id":17581,"section":"COMMON_CUSTOMER_SECTION","fieldName":"Customer Case # with Demo - VMware (Optional)","value":""},{"id":17582,"section":"PROBLEM_SECTION","fieldName":"Version","value":"1"},{"id":17583,"section":"COMMON_CUSTOMER_SECTION","fieldName":"Serial Number","value":"1"},{"id":17584,"section":"COMMON_CUSTOMER_SECTION","fieldName":"Region","value":"Americas"}],"submittedBy":{"id":8705,"username":null,"firstName":"John","lastName":"Smith","email":"John.Smith@cisco.com","phone":"4155551212","phoneCountryCode":"VG","city":"Baton Rouge"},"caseNotes":[],"caseResponses":[]}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, body, null));
        Test.startTest();
        	Case caseRecord = [SELECT Id FROM Case LIMIT 1];
        
        	TSANetService.createCollaborationCase(caseRecord.Id, json, null);
        Test.stopTest();
    }
    
    @isTest
    public static void approveIncomingRequestTest(){
        String body = '{"id":2727,"submitCompanyName":"Demo - VMware","submitCompanyId":1072,"submitterCaseNumber":"00001026","receiveCompanyName":"Demo - Cisco","receiveCompanyId":1071,"receiverCaseNumber":"2727","summary":"lkj","description":"l;kjlkjl;k","priority":"MEDIUM","status":"ACCEPTED","token":"636BqK44MlNnAJx6Yj","createdAt":"2024-07-05T19:15:05Z","updatedAt":"2024-07-16T16:22:47Z","deletedAt":null,"responded":true,"respondBy":"2024-07-05T23:15:05Z","feedbackRequested":false,"reminderSent":false,"priorityNote":"<p>Priority 2 (4 hours)</p>","escalationInstructions":"<p>test.  <a href=\"https://tsanet.org\" rel=\"noopener noreferrer\" target=\"_blank\"> This is a test</a></p>","testCase":false,"customFields":[{"id":17521,"section":"COMMON_CUSTOMER_SECTION","fieldName":"Customer Phone Including Country Code","value":""},{"id":17522,"section":"COMMON_CUSTOMER_SECTION","fieldName":"Customer Case # with Demo - Cisco (Optional)","value":""},{"id":17518,"section":"COMMON_CUSTOMER_SECTION","fieldName":"Customer Company","value":""},{"id":17519,"section":"COMMON_CUSTOMER_SECTION","fieldName":"Customer Name","value":""},{"id":17520,"section":"COMMON_CUSTOMER_SECTION","fieldName":"Customer Email","value":""}],"submittedBy":{"id":8706,"username":null,"firstName":"Sue","lastName":"Test","email":"sue.test@vmware.com","phone":"4155551212","phoneCountryCode":"US","city":"Baton Rouge"},"caseNotes":[],"caseResponses":[{"id":2141,"type":"APPROVAL","caseNumber":"2727","engineerName":"sean dulac","engineerPhone":"(225) 402-9626","engineerEmail":"John.Smith@cisco.com","nextSteps":"Our assigned engineer will contact you.","createdAt":null}]}';
        String json = '{ "caseNumber":"2673", "engineerName":"Sue Test", "engineerEmail":"tsanetdev2@appko.com", "engineerPhone":"+1412848124824", "nextSteps":"Our assigned engineer will contact you." }';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, body, null));
        Test.startTest();
        	Case caseRecord = [SELECT Id FROM Case LIMIT 1];
        
        	TSANetService.approveIncomingRequest('token', json, null);
        Test.stopTest();
    }
    
    /*
    @isTest
    public static void helpTest(){
        TSANetService.helpTest();
    }
*/
}