@IsTest
public class TSANetRefreshUtilsTest {

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
    public static void refreshTest(){
        String json = '{ "content": [ { "id": 2803, "submitCompanyName": "Demo - VMware", "submitCompanyId": 1100, "submitterCaseNumber": "000011111", "receiveCompanyName": "Demo - Cisco", "receiveCompanyId": 1099, "receiverCaseNumber": "00001029", "summary": "summary problem", "description": null, "direction": "INBOUND", "priority": "LOW", "status": "CLOSED", "token": "vTLnUw4rUhHqiLo5vY4k", "createdAt": "2025-02-11T11:37:55Z", "updatedAt": "2025-02-16T11:38:02Z", "deletedAt": null, "responded": true, "respondBy": "2025-02-12T11:37:55Z", "feedbackRequested": true, "reminderSent": false, "priorityNote": "Initial response by the <strong>next business day</strong>. The Mutual Customer’s entitlement with member may affect response times", "escalationInstructions": "<p>Cisco escalation instructions go here....</p>", "testCase": false, "customFields": [], "submittedBy": { "id": 8837, "username": null, "firstName": "Sue", "lastName": "Test", "email": "sue.test@vmware.com", "phone": "9134789654", "phoneCountryCode": "US", "city": "Baton Rouge" }, "caseNotes": [], "caseResponses": [ { "id": 2309, "type": "APPROVAL", "caseNumber": "00001029", "engineerName": "Orest Vasylenko", "engineerPhone": null, "engineerEmail": "orest@appko.com", "nextSteps": "Approved!", "createdAt": "2025-02-11T12:06:01Z" } ] }, { "id": 2819, "submitCompanyName": "Demo - Cisco", "submitCompanyId": 1099, "submitterCaseNumber": "CAS-47732-V4V6K6", "receiveCompanyName": "Demo - VMware", "receiveCompanyId": 1100, "receiverCaseNumber": null, "summary": "A Mineral Build Up in Water Supply", "description": null, "direction": "OUTBOUND", "priority": "LOW", "status": "CLOSED", "token": "SrExIERGZeOmknYx0w", "createdAt": "2025-02-25T16:32:51Z", "updatedAt": "2025-03-02T16:33:02Z", "deletedAt": null, "responded": false, "respondBy": "2025-02-26T16:32:51Z", "feedbackRequested": true, "reminderSent": true, "priorityNote": "Initial response within <strong>24 hours</strong>. The Mutual Customer’s entitlement with member may affect response times", "escalationInstructions": "<p>test Vmware escalation</p>", "testCase": false, "customFields": [], "submittedBy": { "id": 8833, "username": null, "firstName": "John", "lastName": "Smith", "email": "John.Smith@cisco.com", "phone": "4155551212", "phoneCountryCode": "US", "city": "Baton Rouge" }, "caseNotes": [ { "id": 3575, "caseId": 2819, "creatorUsername": null, "creatorEmail": null, "creatorName": "SYSTEM", "summary": "Your case has been closed due to 30 days of inactivity.", "description": "", "priority": "LOW", "status": "ENTERED", "token": "H0RQ40iUX2Sw7t7dIEcU", "createdAt": "2025-04-02T00:00:04Z", "updatedAt": "2025-04-02T00:00:05Z" } ], "caseResponses": [] } ] }';

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, json, null));

        Test.startTest();
        	TSANetRefreshUtils controller = new TSANetRefreshUtils(new ApexPages.StandardController(new tsanetconnect__TSANetCase__c()));
    		controller.refresh();
        Test.stopTest();
    }

    @IsTest
    public static void testCatch(){
        String body = '{ "accessToken": "test.eyJpc3MiOiJodHRwOi8vY29ubmVjdDEucmVub2xhYi51cy9hcGkvYXV0aC9sb2dpbiIsImlhdCI6MTcyMDc3ODk0MiwiZXhwIjoxNzIwNzgyNTQyLCJuYmYiOjE3MjA3Nzg5NDIsImp0aSI6ImJrcDBGZ0k4T2ViNXdxU28iLCJzdWIiOiI4NzA1IiwicHJ2IjoiODdlMGFmMWVmOWZkMTU4MTJmZGVjOTcxNTNhMTRlMGIwNDc1NDZhYSJ9.YbmRLRwdzcua0lh3mCawfb7dvx5LQqJwrboZG4wGFEo", "tokenType": "bearer", "expiresIn": 3600 }';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(500, body, null));

        Test.startTest();
        try	{
            delete [SELECT Id FROM tsanetconnect__TSANet_Credentials__c];
            TSANetRefreshUtils controller = new TSANetRefreshUtils(new ApexPages.StandardController(new tsanetconnect__TSANetCase__c()));
    		controller.refresh();
        } catch(Exception e){
            System.assertEquals(true, e.getMessage() != NULL);
        }
        Test.stopTest();
    }

    @IsTest
    public static void refreshTest2(){
        String body = '[ { "id": 2718, "submitCompanyName": "Demo - VMware", "submitCompanyId": 1072, "submitterCaseNumber": "00001036", "receiveCompanyName": "Demo - Cisco", "receiveCompanyId": 1071, "receiverCaseNumber": "2718", "summary": "Beta Summer 2024 release unit test", "description": "Beta Summer 2024 release unit test", "priority": "LOW", "status": "ACCEPTED", "token": "Pp8DCQVVHkkVvd0rpn", "createdAt": "2024-06-19T17:17:00Z", "updatedAt": "2024-06-28T04:54:26Z", "deletedAt": null, "responded": true, "respondBy": "2024-06-20T17:17:00Z", "feedbackRequested": false, "reminderSent": false, "priorityNote": "<p>Priority 3 (24 Hours)</p>", "escalationInstructions": "test", "testCase": false, "customFields": [ { "id": 17465, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Company", "value": "Dickenson plc" }, { "id": 17466, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Name", "value": "sean jones" }, { "id": 17467, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Email", "value": "sean@bur.com" }, { "id": 17468, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Phone Including Country Code", "value": "4155551212" }, { "id": 17469, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Case # with Demo - Cisco (Optional)", "value": "9876" } ], "submittedBy": { "id": 8706, "username": null, "firstName": "Sue", "lastName": "Test", "email": "sue.test@vmware.com", "phone": "4155551212", "phoneCountryCode": "US", "city": "Baton Rouge" }, "caseNotes": [ { "id": 151, "caseId": 2718, "creatorUsername": null, "creatorEmail": "John.Smith@cisco.com", "summary": "new note", "description": "<p>testing</p>", "priority": "low", "status": "entered", "token": "HeRU7whkYdvVXS9Y8p", "createdAt": "2024-06-19T17:20:23Z", "updatedAt": "2024-06-19T17:20:24Z" }, { "id": 154, "caseId": 2718, "creatorUsername": null, "creatorEmail": "sue.test@vmware.com", "summary": "New note from Paul", "description": "<p>Testing</p>", "priority": "low", "status": "entered", "token": "RoI4TxVcrnirlKLxVNiK", "createdAt": "2024-06-28T04:54:25Z", "updatedAt": "2024-06-28T04:54:26Z" } ], "caseResponses": [ { "id": 2136, "type": "APPROVAL", "caseNumber": "2718", "engineerName": "John Smith", "engineerPhone": "+12122241255", "engineerEmail": "John.Smith@cisco.com", "nextSteps": "Our assigned engineer will contact you.", "createdAt": null } ] } ]';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, body, null));

        Test.startTest();
        	TSANetRefreshUtils.refreshOnCase(null);
        Test.stopTest();
    }
}