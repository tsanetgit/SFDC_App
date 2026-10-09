@IsTest
public class TSANetScheduledJobTest {


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
    public static void getRelatedCollaborationCasesTest(){
        String body = '[ { "id": 2718, "submitCompanyName": "Demo - VMware", "submitCompanyId": 1072, "submitterCaseNumber": "00001036", "receiveCompanyName": "Demo - Cisco", "receiveCompanyId": 1071, "receiverCaseNumber": "2718", "summary": "Beta Summer 2024 release unit test", "description": "Beta Summer 2024 release unit test", "priority": "LOW", "status": "ACCEPTED", "token": "Pp8DCQVVHkkVvd0rpn", "createdAt": "2024-06-19T17:17:00Z", "updatedAt": "2024-06-28T04:54:26Z", "deletedAt": null, "responded": true, "respondBy": "2024-06-20T17:17:00Z", "feedbackRequested": false, "reminderSent": false, "priorityNote": "<p>Priority 3 (24 Hours)</p>", "escalationInstructions": "test", "testCase": false, "customFields": [ { "id": 17465, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Company", "value": "Dickenson plc" }, { "id": 17466, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Name", "value": "sean jones" }, { "id": 17467, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Email", "value": "sean@bur.com" }, { "id": 17468, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Phone Including Country Code", "value": "4155551212" }, { "id": 17469, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Case # with Demo - Cisco (Optional)", "value": "9876" } ], "submittedBy": { "id": 8706, "username": null, "firstName": "Sue", "lastName": "Test", "email": "sue.test@vmware.com", "phone": "4155551212", "phoneCountryCode": "US", "city": "Baton Rouge" }, "caseNotes": [ { "id": 151, "caseId": 2718, "creatorUsername": null, "creatorEmail": "John.Smith@cisco.com", "summary": "new note", "description": "<p>testing</p>", "priority": "low", "status": "entered", "token": "HeRU7whkYdvVXS9Y8p", "createdAt": "2024-06-19T17:20:23Z", "updatedAt": "2024-06-19T17:20:24Z" }, { "id": 154, "caseId": 2718, "creatorUsername": null, "creatorEmail": "sue.test@vmware.com", "summary": "New note from Paul", "description": "<p>Testing</p>", "priority": "low", "status": "entered", "token": "RoI4TxVcrnirlKLxVNiK", "createdAt": "2024-06-28T04:54:25Z", "updatedAt": "2024-06-28T04:54:26Z" } ], "caseResponses": [ { "id": 2136, "type": "APPROVAL", "caseNumber": "2718", "engineerName": "John Smith", "engineerPhone": "+12122241255", "engineerEmail": "John.Smith@cisco.com", "nextSteps": "Our assigned engineer will contact you.", "createdAt": null } ] } ]';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, body, null));

        Test.startTest();
        Datetime dt = Datetime.now().addMinutes(1);
        String cronExp = '0 '+ dt.minute() + ' * ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year();
        System.schedule('TSANetScheduledJobTest', cronExp, new TSANetScheduledJob());

        Id caseId = [SELECT Id FROM Case LIMIT 1].Id;
        TSANetData data = ParserManager.parseTSANetCases(body, caseId);
        Test.stopTest();

        System.assertEquals(1, data.cases.size(), 'Expected one parsed collaboration case');
        System.assertEquals('Pp8DCQVVHkkVvd0rpn', data.cases[0].tsanetconnect__Token__c,
            'The parsed case should carry the TSANet token');
        System.assertEquals(1, [
            SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name = 'TSANetScheduledJobTest'
        ], 'The sync job should be scheduled');
    }

    @IsTest
    static void test_execute_skipsWhenDisconnected() {
        tsanetconnect__TSANet_Credentials__c cred = [
            SELECT Id FROM tsanetconnect__TSANet_Credentials__c WITH USER_MODE LIMIT 1
        ];
        cred.tsanetconnect__isConnected__c = false;
        update cred;

        Test.startTest();
            new TSANetScheduledJob().execute(null);
        Test.stopTest();

        System.assertEquals(0, [
            SELECT COUNT() FROM AsyncApexJob WHERE ApexClass.Name = 'TSANetQueueableJob'
        ], 'A disconnected credential must not enqueue TSANetQueueableJob');
    }

    @IsTest
    static void test_execute_enqueuesWhenConnected() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, '{"totalPages":1,"content":[]}', null));

        Test.startTest();
            new TSANetScheduledJob().execute(null);
        Test.stopTest();

        System.assertEquals(1, [
            SELECT COUNT() FROM AsyncApexJob WHERE ApexClass.Name = 'TSANetQueueableJob'
        ], 'A connected credential should enqueue TSANetQueueableJob');
    }
}
