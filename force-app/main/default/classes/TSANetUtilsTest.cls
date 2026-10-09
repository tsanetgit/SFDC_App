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
        tsanetconnect__TSANetCase__c[] cases = TSANetUtils.getTSANetCases(caseRecord.Id);
        Test.stopTest();

        System.assertNotEquals(null, cases, 'Expected the linked collaboration cases');
        System.assertEquals(1, [
            SELECT COUNT() FROM tsanetconnect__TSANetCase__c
            WHERE tsanetconnect__Token__c = 'Pp8DCQVVHkkVvd0rpn'
        ], 'The API case should have been upserted locally');
    }


    @IsTest
    public static void getTSANetInfoTest(){
        tsanetconnect__TSANetCase__c tsaNetCase = [SELECT Id FROM tsanetconnect__TSANetCase__c WITH USER_MODE LIMIT 1];

        Test.startTest();
            TSANetUtils.TSANetCaseInfo info = TSANetUtils.getTSANetInfo(tsaNetCase.Id);
            tsanetconnect__TSANetCase__c pageInfo = TSANetUtils.getTSANetRecordPageInfo(tsaNetCase.Id);
        Test.stopTest();

        System.assertEquals(tsaNetCase.Id, info.record.Id, 'Expected the requested TSANet case');
        System.assertNotEquals(null, info.caseRecord, 'Expected the linked Salesforce Case');
        System.assertEquals(UserInfo.getUserId(), info.user.Id, 'Expected the running user');
        System.assertEquals(tsaNetCase.Id, pageInfo.Id, 'Record-page info should return the same record');
    }


    @IsTest
    public static void getCasesTest(){
        Case existing = [SELECT Id, CaseNumber FROM Case WITH USER_MODE LIMIT 1];
        Test.setFixedSearchResults(new Id[]{ existing.Id });

        Test.startTest();
            Case[] recent = TSANetUtils.getCases('');
            Case[] found = TSANetUtils.getCases(existing.CaseNumber);
            Case[] tooShort = TSANetUtils.getCases('a');
        Test.stopTest();

        System.assertNotEquals(null, recent, 'Recent cases should never be null');
        System.assertEquals(1, found.size(), 'SOSL should return the fixed search result');
        System.assertEquals(existing.Id, found[0].Id, 'SOSL should return the matching case');
        System.assertEquals(0, tooShort.size(), 'A single-character term is below the search minimum');
    }


    @IsTest
    public static void getNewAccessTokenTest(){
        String body = '{ "company": { "id": 1071, "name": "Demo - Cisco" } }';

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, body, null));

        Test.startTest();
        	Boolean reconnected = TSANetUtils.getNewAccessToken();
        Test.stopTest();

        System.assertEquals(true, reconnected, 'A configured Named Credential should start the reconnect');
    }


    @IsTest
    public static void getCaseInformationTest(){

        String body = '[ { "id": 2718, "submitCompanyName": "Demo - VMware", "submitCompanyId": 1072, "submitterCaseNumber": "00001036", "receiveCompanyName": "Demo - Cisco", "receiveCompanyId": 1071, "receiverCaseNumber": "2718", "summary": "Beta Summer 2024 release unit test", "description": "Beta Summer 2024 release unit test", "priority": "LOW", "status": "ACCEPTED", "token": "Pp8DCQVVHkkVvd0rpn", "createdAt": "2024-06-19T17:17:00Z", "updatedAt": "2024-06-28T04:54:26Z", "deletedAt": null, "responded": true, "respondBy": "2024-06-20T17:17:00Z", "feedbackRequested": false, "reminderSent": false, "priorityNote": "<p>Priority 3 (24 Hours)</p>", "escalationInstructions": "test", "testCase": false, "customFields": [ { "id": 17465, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Company", "value": "Dickenson plc" }, { "id": 17466, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Name", "value": "sean jones" }, { "id": 17467, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Email", "value": "sean@bur.com" }, { "id": 17468, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Phone Including Country Code", "value": "4155551212" }, { "id": 17469, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Case # with Demo - Cisco (Optional)", "value": "9876" } ], "submittedBy": { "id": 8706, "username": null, "firstName": "Sue", "lastName": "Test", "email": "sue.test@vmware.com", "phone": "4155551212", "phoneCountryCode": "US", "city": "Baton Rouge" }, "caseNotes": [ { "id": 151, "caseId": 2718, "creatorUsername": null, "creatorEmail": "John.Smith@cisco.com", "summary": "new note", "description": "<p>testing</p>", "priority": "low", "status": "entered", "token": "HeRU7whkYdvVXS9Y8p", "createdAt": "2024-06-19T17:20:23Z", "updatedAt": "2024-06-19T17:20:24Z" }, { "id": 154, "caseId": 2718, "creatorUsername": null, "creatorEmail": "sue.test@vmware.com", "summary": "New note from Paul", "description": "<p>Testing</p>", "priority": "low", "status": "entered", "token": "RoI4TxVcrnirlKLxVNiK", "createdAt": "2024-06-28T04:54:25Z", "updatedAt": "2024-06-28T04:54:26Z" } ], "caseResponses": [ { "id": 2136, "type": "APPROVAL", "caseNumber": "2718", "engineerName": "John Smith", "engineerPhone": "+12122241255", "engineerEmail": "John.Smith@cisco.com", "nextSteps": "Our assigned engineer will contact you.", "createdAt": null } ] } ]';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, body, null));

        Case caseRecord = [SELECT Id FROM Case WITH USER_MODE LIMIT 1];
        Test.startTest();
        	TSANetUtils.CaseInformation info = TSANetUtils.getCaseInformation(caseRecord.Id);
        Test.stopTest();

        System.assertNotEquals(null, info, 'Case information should be returned');
        System.assertEquals(caseRecord.Id, info.caseRecord.Id, 'Expected the requested Case');
        System.assertNotEquals(null, info.relatedCases, 'Related collaboration cases should be populated');
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

        TSANetService.refreshAfterAction = true;

        Test.startTest();
        	TSANetUtils.futureRefresh(null);
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'Queueable'],
            'The refresh should enqueue exactly one collaboration-case job');
    }
}