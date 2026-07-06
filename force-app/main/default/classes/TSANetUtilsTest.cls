@IsTest

public class TSANetUtilsTest {

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
    public static void getTSANetCasesTest(){
        String body = '[ { "id": 2718, "submitCompanyName": "Demo - VMware", "submitCompanyId": 1072, "submitterCaseNumber": "00001036", "receiveCompanyName": "Demo - Cisco", "receiveCompanyId": 1071, "receiverCaseNumber": "2718", "summary": "Beta Summer 2024 release unit test", "description": "Beta Summer 2024 release unit test", "priority": "LOW", "status": "ACCEPTED", "token": "Pp8DCQVVHkkVvd0rpn", "createdAt": "2024-06-19T17:17:00Z", "updatedAt": "2024-06-28T04:54:26Z", "deletedAt": null, "responded": true, "respondBy": "2024-06-20T17:17:00Z", "feedbackRequested": false, "reminderSent": false, "priorityNote": "<p>Priority 3 (24 Hours)</p>", "escalationInstructions": "test", "testCase": false, "customFields": [ { "id": 17465, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Company", "value": "Dickenson plc" }, { "id": 17466, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Name", "value": "sean jones" }, { "id": 17467, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Email", "value": "sean@bur.com" }, { "id": 17468, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Phone Including Country Code", "value": "4155551212" }, { "id": 17469, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Case # with Demo - Cisco (Optional)", "value": "9876" } ], "submittedBy": { "id": 8706, "username": null, "firstName": "Sue", "lastName": "Test", "email": "sue.test@vmware.com", "phone": "4155551212", "phoneCountryCode": "US", "city": "Baton Rouge" }, "caseNotes": [ { "id": 151, "caseId": 2718, "creatorUsername": null, "creatorEmail": "John.Smith@cisco.com", "summary": "new note", "description": "<p>testing</p>", "priority": "low", "status": "entered", "token": "HeRU7whkYdvVXS9Y8p", "createdAt": "2024-06-19T17:20:23Z", "updatedAt": "2024-06-19T17:20:24Z" }, { "id": 154, "caseId": 2718, "creatorUsername": null, "creatorEmail": "sue.test@vmware.com", "summary": "New note from Paul", "description": "<p>Testing</p>", "priority": "low", "status": "entered", "token": "RoI4TxVcrnirlKLxVNiK", "createdAt": "2024-06-28T04:54:25Z", "updatedAt": "2024-06-28T04:54:26Z" } ], "caseResponses": [ { "id": 2136, "type": "APPROVAL", "caseNumber": "2718", "engineerName": "John Smith", "engineerPhone": "+12122241255", "engineerEmail": "John.Smith@cisco.com", "nextSteps": "Our assigned engineer will contact you.", "createdAt": null } ] } ]';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, body, null));
        Test.startTest();
        Case caseRecord = [SELECT Id FROM Case WITH USER_MODE LIMIT 1];
        TSANetUtils.getTSANetCases(caseRecord.Id);
        Test.stopTest();
    }


    @IsTest
    public static void updateUserCredentialsTest(){
        TSANetUtils.updateUserCredentials('username', 'password');
    }


    @IsTest
    public static void getTSANetInfoTest(){
        tsanetconnect__TSANetCase__c tsaNetCase = [SELECT Id FROM tsanetconnect__TSANetCase__c WITH USER_MODE LIMIT 1];
        TSANetUtils.getTSANetInfo(tsaNetCase.Id);
        TSANetUtils.getTSANetRecordPageInfo(tsaNetCase.Id);
    }


    @IsTest
    public static void getCasesTest(){
        TSANetUtils.getCases('');
        TSANetUtils.getCases('test');
    }


    @IsTest
    public static void getNewAccessTokenTest(){
        String body = '{ "accessToken": "test.eyJpc3MiOiJodHRwOi8vY29ubmVjdDEucmVub2xhYi51cy9hcGkvYXV0aC9sb2dpbiIsImlhdCI6MTcyMDc3ODk0MiwiZXhwIjoxNzIwNzgyNTQyLCJuYmYiOjE3MjA3Nzg5NDIsImp0aSI6ImJrcDBGZ0k4T2ViNXdxU28iLCJzdWIiOiI4NzA1IiwicHJ2IjoiODdlMGFmMWVmOWZkMTU4MTJmZGVjOTcxNTNhMTRlMGIwNDc1NDZhYSJ9.YbmRLRwdzcua0lh3mCawfb7dvx5LQqJwrboZG4wGFEo", "tokenType": "bearer", "expiresIn": 3600 }';

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, body, null));

        String body2 = '{ "company": { "id": 1071, "name": "Demo - Cisco", "description": null }, "user": { "id": 8705, "username": null, "firstName": "John", "lastName": "Smith", "email": "John.Smith@cisco.com", "phone": "4155551212", "phoneCountryCode": "VG", "city": "Baton Rouge" }, "encodedCredentials": "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwOi8vY29ubmVjdDEucmVub2xhYi51cy9hcGkvYXV0aC9sb2dpbiIsImlhdCI6MTcyMDc3ODk0MiwiZXhwIjoxNzIwNzgyNTQyLCJuYmYiOjE3MjA3Nzg5NDIsImp0aSI6ImJrcDBGZ0k4T2ViNXdxU28iLCJzdWIiOiI4NzA1IiwicHJ2IjoiODdlMGFmMWVmOWZkMTU4MTJmZGVjOTcxNTNhMTRlMGIwNDc1NDZhYSJ9.YbmRLRwdzcua0lh3mCawfb7dvx5LQqJwrboZG4wGFEo" }';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, body2, null));
        Test.startTest();
        	TSANetUtils.getNewAccessToken();
        Test.stopTest();
    }


    @IsTest
    public static void updateTSANetCaseTest(){
        tsanetconnect__TSANetCase__c tsaNetCase = [SELECT Id FROM tsanetconnect__TSANetCase__c WITH USER_MODE LIMIT 1];
        TSANetUtils.updateTSANetCase(tsaNetCase.Id, null);
    }



    @IsTest
    public static void getCaseInformationTest(){

        String body = '[ { "id": 2718, "submitCompanyName": "Demo - VMware", "submitCompanyId": 1072, "submitterCaseNumber": "00001036", "receiveCompanyName": "Demo - Cisco", "receiveCompanyId": 1071, "receiverCaseNumber": "2718", "summary": "Beta Summer 2024 release unit test", "description": "Beta Summer 2024 release unit test", "priority": "LOW", "status": "ACCEPTED", "token": "Pp8DCQVVHkkVvd0rpn", "createdAt": "2024-06-19T17:17:00Z", "updatedAt": "2024-06-28T04:54:26Z", "deletedAt": null, "responded": true, "respondBy": "2024-06-20T17:17:00Z", "feedbackRequested": false, "reminderSent": false, "priorityNote": "<p>Priority 3 (24 Hours)</p>", "escalationInstructions": "test", "testCase": false, "customFields": [ { "id": 17465, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Company", "value": "Dickenson plc" }, { "id": 17466, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Name", "value": "sean jones" }, { "id": 17467, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Email", "value": "sean@bur.com" }, { "id": 17468, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Phone Including Country Code", "value": "4155551212" }, { "id": 17469, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Case # with Demo - Cisco (Optional)", "value": "9876" } ], "submittedBy": { "id": 8706, "username": null, "firstName": "Sue", "lastName": "Test", "email": "sue.test@vmware.com", "phone": "4155551212", "phoneCountryCode": "US", "city": "Baton Rouge" }, "caseNotes": [ { "id": 151, "caseId": 2718, "creatorUsername": null, "creatorEmail": "John.Smith@cisco.com", "summary": "new note", "description": "<p>testing</p>", "priority": "low", "status": "entered", "token": "HeRU7whkYdvVXS9Y8p", "createdAt": "2024-06-19T17:20:23Z", "updatedAt": "2024-06-19T17:20:24Z" }, { "id": 154, "caseId": 2718, "creatorUsername": null, "creatorEmail": "sue.test@vmware.com", "summary": "New note from Paul", "description": "<p>Testing</p>", "priority": "low", "status": "entered", "token": "RoI4TxVcrnirlKLxVNiK", "createdAt": "2024-06-28T04:54:25Z", "updatedAt": "2024-06-28T04:54:26Z" } ], "caseResponses": [ { "id": 2136, "type": "APPROVAL", "caseNumber": "2718", "engineerName": "John Smith", "engineerPhone": "+12122241255", "engineerEmail": "John.Smith@cisco.com", "nextSteps": "Our assigned engineer will contact you.", "createdAt": null } ] } ]';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, body, null));

        Case caseRecord = [SELECT Id FROM Case WITH USER_MODE LIMIT 1];
        Test.startTest();
        	TSANetUtils.getCaseInformation(caseRecord.Id);
        Test.stopTest();
    }


    @IsTest
    public static void getCaseInformationBadTest(){
        String body = '{ "error": "message" }';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(400, body, null));

        Test.startTest();
        try {
            Case caseRecord = [SELECT Id FROM Case WITH USER_MODE LIMIT 1];
            TSANetUtils.getCaseInformation(caseRecord.Id);
        } catch(Exception e){
            System.assertEquals('{ "error": "message" }', e.getMessage());
        }
        Test.stopTest();
    }


    @IsTest
    public static void getOneTSANetCaseTest(){
        User adminUser = [SELECT Id FROM User WHERE Email = 'admin@test.com' WITH USER_MODE LIMIT 1];

        System.runAs(adminUser) {
            tsanetconnect__TSANetCase__c tsaNetCase = [SELECT Id FROM tsanetconnect__TSANetCase__c WITH USER_MODE LIMIT 1];

            Test.startTest();
                tsanetconnect__TSANetCase__c caseRecord = TSANetUtils.getOneTSANetCase(tsaNetCase.Id);
                System.assertEquals(true, caseRecord.Id != NULL);
            Test.stopTest();
        }
    }


    @IsTest
    public static void getNotesSubqueryTest(){
        tsanetconnect__TSANetCase__c tsaNetCase = [
            SELECT Id, tsanetconnect__Case__c
            FROM tsanetconnect__TSANetCase__c
            WITH USER_MODE LIMIT 1
        ];

        insert new tsanetconnect__TSANetNote__c(
            tsanetconnect__TSANetCase__c = tsaNetCase.Id,
            tsanetconnect__Token__c = 'utils-note-token',
            tsanetconnect__Summary__c = 'Case created',
            tsanetconnect__Description__c = '<p>Body</p>',
            tsanetconnect__CreatorName__c = 'Tester',
            tsanetconnect__CompanyName__c = 'Demo',
            tsanetconnect__CreatedAt__c = DateTime.now(),
            tsanetconnect__Priority__c = 'LOW',
            tsanetconnect__Status__c = 'ENTERED'
        );

        Test.startTest();
            tsanetconnect__TSANetCase__c[] cases =
                TSANetCaseSelector.getDetailWithResponsesByCaseId(tsaNetCase.tsanetconnect__Case__c);
        Test.stopTest();

        System.assertEquals(1, cases.size(), 'Expected the linked TSANet case');
        System.assertEquals(1, cases[0].tsanetconnect__TSANetNotes__r.size(),
            'Expected the note to be returned by the notes subquery');
    }


    @IsTest
    public static void createCollaborationCaseTest(){
        String body = '[ { "id": 2718, "submitCompanyName": "Demo - VMware", "submitCompanyId": 1072, "submitterCaseNumber": "00001036", "receiveCompanyName": "Demo - Cisco", "receiveCompanyId": 1071, "receiverCaseNumber": "2718", "summary": "Beta Summer 2024 release unit test", "description": "Beta Summer 2024 release unit test", "priority": "LOW", "status": "ACCEPTED", "token": "Pp8DCQVVHkkVvd0rpn", "createdAt": "2024-06-19T17:17:00Z", "updatedAt": "2024-06-28T04:54:26Z", "deletedAt": null, "responded": true, "respondBy": "2024-06-20T17:17:00Z", "feedbackRequested": false, "reminderSent": false, "priorityNote": "<p>Priority 3 (24 Hours)</p>", "escalationInstructions": "test", "testCase": false, "customFields": [ { "id": 17465, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Company", "value": "Dickenson plc" }, { "id": 17466, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Name", "value": "sean jones" }, { "id": 17467, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Email", "value": "sean@bur.com" }, { "id": 17468, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Phone Including Country Code", "value": "4155551212" }, { "id": 17469, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Case # with Demo - Cisco (Optional)", "value": "9876" } ], "submittedBy": { "id": 8706, "username": null, "firstName": "Sue", "lastName": "Test", "email": "sue.test@vmware.com", "phone": "4155551212", "phoneCountryCode": "US", "city": "Baton Rouge" }, "caseNotes": [ { "id": 151, "caseId": 2718, "creatorUsername": null, "creatorEmail": "John.Smith@cisco.com", "summary": "new note", "description": "<p>testing</p>", "priority": "low", "status": "entered", "token": "HeRU7whkYdvVXS9Y8p", "createdAt": "2024-06-19T17:20:23Z", "updatedAt": "2024-06-19T17:20:24Z" }, { "id": 154, "caseId": 2718, "creatorUsername": null, "creatorEmail": "sue.test@vmware.com", "summary": "New note from Paul", "description": "<p>Testing</p>", "priority": "low", "status": "entered", "token": "RoI4TxVcrnirlKLxVNiK", "createdAt": "2024-06-28T04:54:25Z", "updatedAt": "2024-06-28T04:54:26Z" } ], "caseResponses": [ { "id": 2136, "type": "APPROVAL", "caseNumber": "2718", "engineerName": "John Smith", "engineerPhone": "+12122241255", "engineerEmail": "John.Smith@cisco.com", "nextSteps": "Our assigned engineer will contact you.", "createdAt": null } ] } ]';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, body, null));

        Test.startTest();
        	TSANetUtils.futureRefresh(null);
        Test.stopTest();
    }
}