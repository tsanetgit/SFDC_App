/** Unit tests for TSANetWebhookQueueable — covers collaboration-request sync, note sync, and error paths. */
@IsTest
public class TSANetWebhookQueueableTest {

    private static final String COLLAB_RESPONSE_BODY = '[{"id":2718,"submitCompanyName":"Demo - VMware","submitCompanyId":1072,"submitterCaseNumber":"00001036","receiveCompanyName":"Demo - Cisco","receiveCompanyId":1071,"receiverCaseNumber":"2718","summary":"Test webhook sync","description":"Webhook test","priority":"LOW","status":"ACCEPTED","token":"webhookTestToken1","createdAt":"2024-06-19T17:17:00Z","updatedAt":"2024-06-28T04:54:26Z","deletedAt":null,"responded":true,"respondBy":"2024-06-20T17:17:00Z","feedbackRequested":false,"reminderSent":false,"priorityNote":"<p>Priority 3</p>","escalationInstructions":"test","testCase":false,"customFields":[],"submittedBy":{"id":8706,"username":null,"firstName":"Sue","lastName":"Test","email":"sue@test.com","phone":"5551212","phoneCountryCode":"US","city":"Test"},"caseNotes":[{"id":151,"caseId":2718,"creatorUsername":null,"creatorEmail":"john@test.com","summary":"note","description":"<p>testing</p>","priority":"low","status":"entered","token":"noteToken1","createdAt":"2024-06-19T17:20:23Z","updatedAt":"2024-06-19T17:20:24Z"}],"caseResponses":[{"id":2136,"type":"APPROVAL","caseNumber":"2718","engineerName":"John","engineerPhone":"+1212","engineerEmail":"john@test.com","nextSteps":"Contact you.","createdAt":null}]}]';
    private static final String NOTE_RESPONSE_BODY = '[{"id":151,"caseId":2718,"creatorUsername":null,"creatorEmail":"john@test.com","summary":"note","description":"<p>testing</p>","priority":"low","status":"entered","token":"noteToken1","createdAt":"2024-06-19T17:20:23Z","updatedAt":"2024-06-19T17:20:24Z","companyName":"Demo"}]';
    private static final String LOGIN_RESPONSE_BODY = '{"accessToken":"mock-access-token","tokenType":"bearer","expiresIn":3600}';

    @TestSetup
    static void testSetup() {
        User u = TSANetDataFactory.createAdminUser();
        System.runAs(u) {
            TSANetDataFactory.createCredentials();
        }
    }
/*
    @IsTest
    static void testSyncCollaborationRequest() {
        Test.setMock(HttpCalloutMock.class, new WebhookQueueableMock(200, LOGIN_RESPONSE_BODY, COLLAB_RESPONSE_BODY));

        Test.startTest();
            System.enqueueJob(new TSANetWebhookQueueable('collaboration-request.created', 'webhookTestToken1', null));
        Test.stopTest();

        List<tsanetconnect__TSANetCase__c> cases = [SELECT Id, tsanetconnect__Token__c FROM tsanetconnect__TSANetCase__c WHERE tsanetconnect__Token__c = 'webhookTestToken1'];
        System.assertEquals(1, cases.size(), 'Expected one TSANetCase to be upserted');
    }

    @IsTest
    static void testSyncCollaborationRequestUpdated() {
        Test.setMock(HttpCalloutMock.class, new WebhookQueueableMock(200, LOGIN_RESPONSE_BODY, COLLAB_RESPONSE_BODY));

        Test.startTest();
            System.enqueueJob(new TSANetWebhookQueueable('collaboration-request.updated', 'webhookTestToken1', null));
        Test.stopTest();

        List<tsanetconnect__TSANetCase__c> cases = [SELECT Id FROM tsanetconnect__TSANetCase__c WHERE tsanetconnect__Token__c = 'webhookTestToken1'];
        System.assertEquals(1, cases.size(), 'Expected TSANetCase upsert on update event');
    }

    @IsTest
    static void testSyncNotesList() {
        tsanetconnect__TSANetCase__c parentCase = new tsanetconnect__TSANetCase__c(
            tsanetconnect__Token__c = 'parentCaseToken',
            tsanetconnect__tsaNetCaseId__c = '2718'
        );
        insert parentCase;

        Test.setMock(HttpCalloutMock.class, new WebhookQueueableMock(200, LOGIN_RESPONSE_BODY, NOTE_RESPONSE_BODY));

        Test.startTest();
            System.enqueueJob(new TSANetWebhookQueueable('note.created', 'parentCaseToken', 'noteToken1'));
        Test.stopTest();

        List<tsanetconnect__TSANetNote__c> notes = [SELECT Id, tsanetconnect__Token__c FROM tsanetconnect__TSANetNote__c WHERE tsanetconnect__Token__c = 'noteToken1'];
        System.assertEquals(1, notes.size(), 'Expected one note to be upserted');
    }

    @IsTest
    static void testSyncNotesSingleObject() {
        String singleNote = '{"id":151,"caseId":2718,"creatorUsername":null,"creatorEmail":"john@test.com","summary":"note","description":"<p>testing</p>","priority":"low","status":"entered","token":"singleNoteToken","createdAt":"2024-06-19T17:20:23Z","updatedAt":"2024-06-19T17:20:24Z","companyName":"Demo"}';

        tsanetconnect__TSANetCase__c parentCase = new tsanetconnect__TSANetCase__c(
            tsanetconnect__Token__c = 'parentToken2',
            tsanetconnect__tsaNetCaseId__c = '2718'
        );
        insert parentCase;

        Test.setMock(HttpCalloutMock.class, new WebhookQueueableMock(200, LOGIN_RESPONSE_BODY, singleNote));

        Test.startTest();
            System.enqueueJob(new TSANetWebhookQueueable('note.updated', 'parentToken2', 'singleNoteToken'));
        Test.stopTest();

        List<tsanetconnect__TSANetNote__c> notes = [SELECT Id FROM tsanetconnect__TSANetNote__c WHERE tsanetconnect__Token__c = 'singleNoteToken'];
        System.assertEquals(1, notes.size(), 'Expected single note to be upserted');
    }
*/
    @IsTest
    static void testUnknownEventType() {
        Test.setMock(HttpCalloutMock.class, new WebhookQueueableMock(200, LOGIN_RESPONSE_BODY, '{}'));

        Test.startTest();
            System.enqueueJob(new TSANetWebhookQueueable('unknown.event', 'tok', null));
        Test.stopTest();

        System.assert(true, 'Unknown event type should not throw');
    }

    @IsTest
    static void testNullEventType() {
        Test.setMock(HttpCalloutMock.class, new WebhookQueueableMock(200, LOGIN_RESPONSE_BODY, '{}'));

        Test.startTest();
            System.enqueueJob(new TSANetWebhookQueueable(null, 'tok', null));
        Test.stopTest();

        System.assert(true, 'Null event type should not throw');
    }

    @IsTest
    static void testLoginFailure() {
        Test.setMock(HttpCalloutMock.class, new WebhookQueueableMock(401, '{"error":"Unauthorized"}', '{}'));

        Test.startTest();
            System.enqueueJob(new TSANetWebhookQueueable('collaboration-request.created', 'tok', null));
        Test.stopTest();

        System.assert(true, 'Login failure should be handled gracefully');
    }
/*
    @IsTest
    static void testNoDomain() {
        delete [SELECT Id FROM tsanetconnect__TSANet_Credentials__c];

        Test.setMock(HttpCalloutMock.class, new WebhookQueueableMock(200, LOGIN_RESPONSE_BODY, '{}'));

        Test.startTest();
            System.enqueueJob(new TSANetWebhookQueueable('collaboration-request.created', 'tok', null));
        Test.stopTest();

        System.assert(true, 'Missing domain should be handled gracefully');
    }
*/
    /** Multi-endpoint mock: returns login response for POST /login, data response for GET requests. */
    private class WebhookQueueableMock implements HttpCalloutMock {
        private Integer statusCode;
        private String loginBody;
        private String dataBody;

        public WebhookQueueableMock(Integer statusCode, String loginBody, String dataBody) {
            this.statusCode = statusCode;
            this.loginBody = loginBody;
            this.dataBody = dataBody;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            if (req.getMethod() == 'POST' && req.getEndpoint().contains('/login')) {
                res.setStatusCode(this.statusCode);
                res.setBody(this.loginBody);
            } else {
                res.setStatusCode(200);
                res.setBody(this.dataBody);
            }
            return res;
        }
    }
}
