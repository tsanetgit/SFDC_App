/** Unit tests for the single-collaboration-request refresh path. */
@IsTest
public class TSANetCaseRefreshServiceTest {

    private static final String CASE_TOKEN = 'Pp8DCQVVHkkVvd0rpn';

    /** Captures every request so tests can assert the endpoint that was actually called. */
    private class CapturingMock implements HttpCalloutMock {
        private String body;
        public HttpRequest lastRequest;

        public CapturingMock(String body){
            this.body = body;
        }

        public HttpResponse respond(HttpRequest req){
            lastRequest = req;

            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(body);
            return res;
        }
    }

    @TestSetup
    static void testSetup() {
        User user = TSANetDataFactory.createAdminUser();
        System.runAs(user){
            TSANetDataFactory.createCredentials();
            Account account = TSANetDataFactory.createAccount();
            Contact contact = TSANetDataFactory.createContact(account.Id);
            Case caseRecord = TSANetDataFactory.createCase(account.Id, contact.Id);
            TSANetDataFactory.createTSANetCase(caseRecord.Id);
        }
    }

    /** The API returns one collaboration request object, not the paged list wrapper. */
    private static String singleCaseBody(){
        return '{ "id": 2718, "submitCompanyName": "Demo - VMware", "submitCompanyId": 1072, '
            + '"submitterCaseNumber": "00001036", "receiveCompanyName": "Demo - Cisco", '
            + '"receiveCompanyId": 1071, "receiverCaseNumber": "2718", "summary": "Single case refresh", '
            + '"description": "Single case refresh", "priority": "LOW", "status": "ACCEPTED", '
            + '"token": "' + CASE_TOKEN + '", "createdAt": "2024-06-19T17:17:00Z", '
            + '"updatedAt": "2024-06-28T04:54:26Z", "respondBy": "2024-06-20T17:17:00Z", '
            + '"direction": "OUTBOUND", "priorityNote": "<p>Priority 3</p>", "escalationInstructions": "test", '
            + '"responded": true, "feedbackRequested": false, "reminderSent": false, "testCase": false, '
            + '"customFields": [], '
            + '"submittedBy": { "firstName": "Sue", "lastName": "Test", "email": "sue.test@vmware.com", "phone": "4155551212" }, '
            + '"caseNotes": [], "caseResponses": [] }';
    }

    @IsTest
    static void testRefreshByTokenCallsTheSingleCaseEndpoint(){
        CapturingMock mock = new CapturingMock(singleCaseBody());
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
            TSANetCaseRefreshService.refreshByToken(CASE_TOKEN);
        Test.stopTest();

        System.assertNotEquals(null, mock.lastRequest, 'Expected a callout for the single case');
        System.assertEquals('GET', mock.lastRequest.getMethod(), 'The refresh must be a GET');
        System.assertEquals(true, mock.lastRequest.getEndpoint().endsWith('/v1/collaboration-requests/' + CASE_TOKEN),
            'The refresh must hit the single-case endpoint, found: ' + mock.lastRequest.getEndpoint());
    }

    @IsTest
    static void testRefreshByTokenUpsertsOnlyThatCase(){
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, singleCaseBody(), null));

        Test.startTest();
            TSANetCaseRefreshService.refreshByToken(CASE_TOKEN);
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM tsanetconnect__TSANetError__c],
            'A successful refresh should not log an error');

        tsanetconnect__TSANetCase__c[] refreshed = [
            SELECT Id, tsanetconnect__Summary__c, tsanetconnect__Status__c
            FROM tsanetconnect__TSANetCase__c
            WHERE tsanetconnect__Token__c = :CASE_TOKEN
        ];
        System.assertEquals(1, refreshed.size(), 'Exactly one case should have been upserted');
        System.assertEquals('Single case refresh', refreshed[0].tsanetconnect__Summary__c,
            'The upserted case should carry the API summary');
        System.assertEquals('ACCEPTED', refreshed[0].tsanetconnect__Status__c,
            'The upserted case should carry the API status');
    }

    @IsTest
    static void testRefreshByBlankTokenIsANoOp(){
        CapturingMock mock = new CapturingMock(singleCaseBody());
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
            TSANetCaseRefreshService.refreshByToken(null);
            TSANetCaseRefreshService.refreshByToken('');
        Test.stopTest();

        System.assertEquals(null, mock.lastRequest, 'A blank token must not trigger a callout');
    }

    @IsTest
    static void testEnqueueByTokenQueuesOneJob(){
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, singleCaseBody(), null));

        Test.startTest();
            TSANetCaseRefreshService.enqueueByToken(CASE_TOKEN);
        Test.stopTest();

        System.assertEquals(1, [
            SELECT COUNT() FROM AsyncApexJob
            WHERE JobType = 'Queueable' AND ApexClass.Name = 'TSANetCaseRefreshQueueable'
        ], 'Exactly one single-case refresh job should have been enqueued');
        System.assertEquals(1, [
            SELECT COUNT() FROM tsanetconnect__TSANetCase__c WHERE tsanetconnect__Token__c = :CASE_TOKEN
        ], 'The queued job should have refreshed the case');
    }

    @IsTest
    static void testEnqueueByTokenRespectsTheRefreshSwitch(){
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, singleCaseBody(), null));

        Test.startTest();
            TSANetService.refreshAfterAction = false;
            TSANetCaseRefreshService.enqueueByToken(CASE_TOKEN);
            TSANetService.refreshAfterAction = true;
        Test.stopTest();

        System.assertEquals(0, [
            SELECT COUNT() FROM AsyncApexJob WHERE ApexClass.Name = 'TSANetCaseRefreshQueueable'
        ], 'No job should be queued while the refresh switch is off');
    }

    @IsTest
    static void testEnqueueFromResponseUsesTheTokenInTheBody(){
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, singleCaseBody(), null));
        Case supportCase = [SELECT Id FROM Case LIMIT 1];

        Test.startTest();
            TSANetCaseRefreshService.enqueueFromResponse('{"token":"' + CASE_TOKEN + '"}', supportCase.Id);
        Test.stopTest();

        System.assertEquals(1, [
            SELECT COUNT() FROM AsyncApexJob WHERE ApexClass.Name = 'TSANetCaseRefreshQueueable'
        ], 'A create response carrying a token must refresh only that case');
        System.assertEquals(0, [
            SELECT COUNT() FROM AsyncApexJob WHERE ApexClass.Name = 'TSANetQueueableJob'
        ], 'The full paged sync must not run when the token is known');
    }

    @IsTest
    static void testEnqueueFromResponseFallsBackToTheCaseScopedSync(){
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, singleCaseBody(), null));
        Case supportCase = [SELECT Id FROM Case LIMIT 1];

        Test.startTest();
            TSANetCaseRefreshService.enqueueFromResponse('{"message":"no token here"}', supportCase.Id);
        Test.stopTest();

        System.assertEquals(0, [
            SELECT COUNT() FROM AsyncApexJob WHERE ApexClass.Name = 'TSANetCaseRefreshQueueable'
        ], 'Without a token there is no single case to refresh');
        System.assertEquals(1, [
            SELECT COUNT() FROM AsyncApexJob WHERE ApexClass.Name = 'TSANetQueueableJob'
        ], 'A response without a token must fall back to the Case-scoped sync');
    }
}
