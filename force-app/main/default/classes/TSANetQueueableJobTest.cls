@IsTest

public class TSANetQueueableJobTest {

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
    public static void executeTest(){
        String json = '{ "content": [ { "id": 2803, "submitCompanyName": "Demo - VMware", "submitCompanyId": 1100, "submitterCaseNumber": "000011111", "receiveCompanyName": "Demo - Cisco", "receiveCompanyId": 1099, "receiverCaseNumber": "00001029", "summary": "summary problem", "description": null, "direction": "INBOUND", "priority": "LOW", "status": "CLOSED", "token": "vTLnUw4rUhHqiLo5vY4k", "createdAt": "2025-02-11T11:37:55Z", "updatedAt": "2025-02-16T11:38:02Z", "deletedAt": null, "responded": true, "respondBy": "2025-02-12T11:37:55Z", "feedbackRequested": true, "reminderSent": false, "priorityNote": "Initial response by the <strong>next business day</strong>. The Mutual Customer’s entitlement with member may affect response times", "escalationInstructions": "<p>Cisco escalation instructions go here....</p>", "testCase": false, "customFields": [], "submittedBy": { "id": 8837, "username": null, "firstName": "Sue", "lastName": "Test", "email": "sue.test@vmware.com", "phone": "9134789654", "phoneCountryCode": "US", "city": "Baton Rouge" }, "caseNotes": [], "caseResponses": [ { "id": 2309, "type": "APPROVAL", "caseNumber": "00001029", "engineerName": "Orest Vasylenko", "engineerPhone": null, "engineerEmail": "orest@appko.com", "nextSteps": "Approved!", "createdAt": "2025-02-11T12:06:01Z" } ] }, { "id": 2819, "submitCompanyName": "Demo - Cisco", "submitCompanyId": 1099, "submitterCaseNumber": "CAS-47732-V4V6K6", "receiveCompanyName": "Demo - VMware", "receiveCompanyId": 1100, "receiverCaseNumber": null, "summary": "A Mineral Build Up in Water Supply", "description": null, "direction": "OUTBOUND", "priority": "LOW", "status": "CLOSED", "token": "SrExIERGZeOmknYx0w", "createdAt": "2025-02-25T16:32:51Z", "updatedAt": "2025-03-02T16:33:02Z", "deletedAt": null, "responded": false, "respondBy": "2025-02-26T16:32:51Z", "feedbackRequested": true, "reminderSent": true, "priorityNote": "Initial response within <strong>24 hours</strong>. The Mutual Customer’s entitlement with member may affect response times", "escalationInstructions": "<p>test Vmware escalation</p>", "testCase": false, "customFields": [], "submittedBy": { "id": 8833, "username": null, "firstName": "John", "lastName": "Smith", "email": "John.Smith@cisco.com", "phone": "4155551212", "phoneCountryCode": "US", "city": "Baton Rouge" }, "caseNotes": [ { "id": 3575, "caseId": 2819, "creatorUsername": null, "creatorEmail": null, "creatorName": "SYSTEM", "summary": "Your case has been closed due to 30 days of inactivity.", "description": "", "priority": "LOW", "status": "ENTERED", "token": "H0RQ40iUX2Sw7t7dIEcU", "createdAt": "2025-04-02T00:00:04Z", "updatedAt": "2025-04-02T00:00:05Z" } ], "caseResponses": [] } ] }';

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, json, null));
        Test.startTest();
        	System.enqueueJob(new TSANetQueueableJob(0, null, null, null, null, null));
        Test.stopTest();

        System.assertEquals(1, [
            SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'Queueable' AND Status = 'Completed'
        ], 'The queueable should run to completion');
        System.assertEquals(2, [
            SELECT COUNT() FROM tsanetconnect__TSANetCase__c
            WHERE tsanetconnect__Token__c IN ('vTLnUw4rUhHqiLo5vY4k', 'SrExIERGZeOmknYx0w')
        ], 'Both cases from the paged API response should have been upserted');

    }

    @IsTest
    static void test_enqueueIfConnected_skipsWhenDisconnected() {
        tsanetconnect__TSANet_Credentials__c cred = [
            SELECT Id FROM tsanetconnect__TSANet_Credentials__c WITH USER_MODE LIMIT 1
        ];
        cred.tsanetconnect__isConnected__c = false;
        update cred;

        Test.startTest();
            Boolean enqueued = TSANetQueueableJob.enqueueIfConnected(null);
        Test.stopTest();

        System.assertEquals(false, enqueued, 'Disconnected credentials must not enqueue a sync job');
        System.assertEquals(0, [
            SELECT COUNT() FROM AsyncApexJob WHERE ApexClass.Name = 'TSANetQueueableJob'
        ], 'No TSANetQueueableJob should be created when disconnected');
    }

    @IsTest
    static void test_isAuthenticationFailure() {
        System.assertEquals(true, TSANetQueueableJob.isAuthenticationFailure(new CalloutException('Unauthorized')));
        System.assertEquals(true, TSANetQueueableJob.isAuthenticationFailure(new CalloutException('Unable to fetch the OAuth token.')));
        System.assertEquals(false, TSANetQueueableJob.isAuthenticationFailure(new CalloutException('timeout')));
        System.assertEquals(false, TSANetQueueableJob.isAuthenticationFailure(null));
    }

    @IsTest
    static void test_execute_authFailure_marksDisconnected() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(401, '{"message":"Unauthorized"}', null));

        Test.startTest();
            System.enqueueJob(new TSANetQueueableJob(0, null, null, null, null, null));
        Test.stopTest();

        System.assertEquals(false, [
            SELECT tsanetconnect__isConnected__c FROM tsanetconnect__TSANet_Credentials__c LIMIT 1
        ].tsanetconnect__isConnected__c, 'A catchable auth failure should disconnect the primary credential');
    }
}