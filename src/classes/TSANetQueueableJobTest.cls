@isTest
public class TSANetQueueableJobTest {
    
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
        
        tsanet_connect__TSANetCase__c tsaNetCase = new tsanet_connect__TSANetCase__c(tsanet_connect__Token__c = 'test-token', tsanet_connect__CaseToken__c = 'test-token', tsanet_connect__Case__c = caseRecord.Id);
        insert tsaNetCase;
	}

    @isTest
    public static void executeTest(){
        String json = '{ "content": [ { "id": 2803, "submitCompanyName": "Demo - VMware", "submitCompanyId": 1100, "submitterCaseNumber": "000011111", "receiveCompanyName": "Demo - Cisco", "receiveCompanyId": 1099, "receiverCaseNumber": "00001029", "summary": "summary problem", "description": null, "direction": "INBOUND", "priority": "LOW", "status": "CLOSED", "token": "vTLnUw4rUhHqiLo5vY4k", "createdAt": "2025-02-11T11:37:55Z", "updatedAt": "2025-02-16T11:38:02Z", "deletedAt": null, "responded": true, "respondBy": "2025-02-12T11:37:55Z", "feedbackRequested": true, "reminderSent": false, "priorityNote": "Initial response by the <strong>next business day</strong>. The Mutual Customer’s entitlement with member may affect response times", "escalationInstructions": "<p>Cisco escalation instructions go here....</p>", "testCase": false, "customFields": [], "submittedBy": { "id": 8837, "username": null, "firstName": "Sue", "lastName": "Test", "email": "sue.test@vmware.com", "phone": "9134789654", "phoneCountryCode": "US", "city": "Baton Rouge" }, "caseNotes": [], "caseResponses": [ { "id": 2309, "type": "APPROVAL", "caseNumber": "00001029", "engineerName": "Orest Vasylenko", "engineerPhone": null, "engineerEmail": "orest@appko.com", "nextSteps": "Approved!", "createdAt": "2025-02-11T12:06:01Z" } ] }, { "id": 2819, "submitCompanyName": "Demo - Cisco", "submitCompanyId": 1099, "submitterCaseNumber": "CAS-47732-V4V6K6", "receiveCompanyName": "Demo - VMware", "receiveCompanyId": 1100, "receiverCaseNumber": null, "summary": "A Mineral Build Up in Water Supply", "description": null, "direction": "OUTBOUND", "priority": "LOW", "status": "CLOSED", "token": "SrExIERGZeOmknYx0w", "createdAt": "2025-02-25T16:32:51Z", "updatedAt": "2025-03-02T16:33:02Z", "deletedAt": null, "responded": false, "respondBy": "2025-02-26T16:32:51Z", "feedbackRequested": true, "reminderSent": true, "priorityNote": "Initial response within <strong>24 hours</strong>. The Mutual Customer’s entitlement with member may affect response times", "escalationInstructions": "<p>test Vmware escalation</p>", "testCase": false, "customFields": [], "submittedBy": { "id": 8833, "username": null, "firstName": "John", "lastName": "Smith", "email": "John.Smith@cisco.com", "phone": "4155551212", "phoneCountryCode": "US", "city": "Baton Rouge" }, "caseNotes": [ { "id": 3575, "caseId": 2819, "creatorUsername": null, "creatorEmail": null, "creatorName": "SYSTEM", "summary": "Your case has been closed due to 30 days of inactivity.", "description": "", "priority": "LOW", "status": "ENTERED", "token": "H0RQ40iUX2Sw7t7dIEcU", "createdAt": "2025-04-02T00:00:04Z", "updatedAt": "2025-04-02T00:00:05Z" } ], "caseResponses": [] } ] }';
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, json, null));
        Test.startTest();
        	System.enqueueJob(new TSANetQueueableJob(0, null, null, null, null));
        Test.stopTest();
        
    }
}