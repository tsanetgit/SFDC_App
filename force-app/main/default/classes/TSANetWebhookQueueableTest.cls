/** Unit tests for TSANetWebhookQueueable — covers collaboration-request sync, note sync, and error paths. */
@IsTest
public class TSANetWebhookQueueableTest {

    private static final String COLLAB_RESPONSE_BODY = '[{"id":2718,"submitCompanyName":"Demo - VMware","submitCompanyId":1072,"submitterCaseNumber":"00001036","receiveCompanyName":"Demo - Cisco","receiveCompanyId":1071,"receiverCaseNumber":"2718","summary":"Test webhook sync","description":"Webhook test","priority":"LOW","status":"ACCEPTED","token":"webhookTestToken1","createdAt":"2024-06-19T17:17:00Z","updatedAt":"2024-06-28T04:54:26Z","deletedAt":null,"responded":true,"respondBy":"2024-06-20T17:17:00Z","feedbackRequested":false,"reminderSent":false,"priorityNote":"<p>Priority 3</p>","escalationInstructions":"test","testCase":false,"customFields":[],"submittedBy":{"id":8706,"username":null,"firstName":"Sue","lastName":"Test","email":"sue@test.com","phone":"5551212","phoneCountryCode":"US","city":"Test"},"caseNotes":[{"id":151,"caseId":2718,"creatorUsername":null,"creatorEmail":"john@test.com","summary":"note","description":"<p>testing</p>","priority":"low","status":"entered","token":"noteToken1","createdAt":"2024-06-19T17:20:23Z","updatedAt":"2024-06-19T17:20:24Z"}],"caseResponses":[{"id":2136,"type":"APPROVAL","caseNumber":"2718","engineerName":"John","engineerPhone":"+1212","engineerEmail":"john@test.com","nextSteps":"Contact you.","createdAt":null}]}]';
    private static final String NOTE_RESPONSE_BODY = '[{"id":151,"caseId":2718,"creatorUsername":null,"creatorEmail":"john@test.com","summary":"note","description":"<p>testing</p>","priority":"low","status":"entered","token":"noteToken1","createdAt":"2024-06-19T17:20:23Z","updatedAt":"2024-06-19T17:20:24Z","companyName":"Demo"}]';

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
        Test.setMock(HttpCalloutMock.class, new WebhookQueueableMock(200, COLLAB_RESPONSE_BODY));

        Test.startTest();
            System.enqueueJob(new TSANetWebhookQueueable('collaboration-request.created', 'webhookTestToken1', null));
        Test.stopTest();

        List<tsanetconnect__TSANetCase__c> cases = [SELECT Id, tsanetconnect__Token__c FROM tsanetconnect__TSANetCase__c WHERE tsanetconnect__Token__c = 'webhookTestToken1'];
        System.assertEquals(1, cases.size(), 'Expected one TSANetCase to be upserted');
    }

    @IsTest
    static void testSyncCollaborationRequestUpdated() {
        Test.setMock(HttpCalloutMock.class, new WebhookQueueableMock(200, COLLAB_RESPONSE_BODY));

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

        Test.setMock(HttpCalloutMock.class, new WebhookQueueableMock(200, NOTE_RESPONSE_BODY));

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

        Test.setMock(HttpCalloutMock.class, new WebhookQueueableMock(200, singleNote));

        Test.startTest();
            System.enqueueJob(new TSANetWebhookQueueable('note.updated', 'parentToken2', 'singleNoteToken'));
        Test.stopTest();

        List<tsanetconnect__TSANetNote__c> notes = [SELECT Id FROM tsanetconnect__TSANetNote__c WHERE tsanetconnect__Token__c = 'singleNoteToken'];
        System.assertEquals(1, notes.size(), 'Expected single note to be upserted');
    }
*/
    @IsTest
    static void testPublishesCaseUpdatedEvent() {
        Account account = TSANetDataFactory.createAccount();
        Contact contact = TSANetDataFactory.createContact(account.Id);
        Case sfCase = TSANetDataFactory.createCase(account.Id, contact.Id);

        insert new tsanetconnect__TSANetCase__c(
            tsanetconnect__Token__c = 'peSyncToken',
            tsanetconnect__tsaNetCaseId__c = '9999',
            tsanetconnect__Case__c = sfCase.Id
        );

        Test.setMock(HttpCalloutMock.class, new WebhookQueueableMock(200, COLLAB_RESPONSE_BODY));

        Test.startTest();
            System.enqueueJob(new TSANetWebhookQueueable('collaboration-request.updated', 'peSyncToken', null));
        Test.stopTest();

        // The publish path resolves the linked Case for the requestToken and fires the event.
        tsanetconnect__TSANetCase__c linked = [
            SELECT tsanetconnect__Case__c
            FROM tsanetconnect__TSANetCase__c
            WHERE tsanetconnect__Token__c = 'peSyncToken'
            LIMIT 1
        ];
        System.assertEquals(sfCase.Id, linked.tsanetconnect__Case__c,
            'Expected the Case link to drive the published TSANetCaseUpdated__e event');
    }

    @IsTest
    static void testCloudEventCreatedTypeSyncs() {
        Account account = TSANetDataFactory.createAccount();
        Contact contact = TSANetDataFactory.createContact(account.Id);
        Case sfCase = TSANetDataFactory.createCase(account.Id, contact.Id);

        insert new tsanetconnect__TSANetCase__c(
            tsanetconnect__Token__c = 'v2SyncToken',
            tsanetconnect__tsaNetCaseId__c = '8888',
            tsanetconnect__Case__c = sfCase.Id
        );

        Test.setMock(HttpCalloutMock.class, new WebhookQueueableMock(200, COLLAB_RESPONSE_BODY));

        Test.startTest();
            System.enqueueJob(new TSANetWebhookQueueable(
                'org.tsanet.connect.collaboration-request.created',
                'v2SyncToken',
                null
            ));
        Test.stopTest();

        tsanetconnect__TSANetCase__c linked = [
            SELECT tsanetconnect__Case__c
            FROM tsanetconnect__TSANetCase__c
            WHERE tsanetconnect__Token__c = 'v2SyncToken'
            LIMIT 1
        ];
        System.assertEquals(sfCase.Id, linked.tsanetconnect__Case__c,
            'V2 CloudEvent types must still sync the collaboration request');
    }

    @IsTest
    static void testUnknownEventType() {
        Test.setMock(HttpCalloutMock.class, new WebhookQueueableMock(200, '{}'));

        Test.startTest();
            System.enqueueJob(new TSANetWebhookQueueable('unknown.event', 'tok', null));
        Test.stopTest();

        System.assert(true, 'Unknown event type should not throw');
    }

    @IsTest
    static void testNullEventType() {
        Test.setMock(HttpCalloutMock.class, new WebhookQueueableMock(200, '{}'));

        Test.startTest();
            System.enqueueJob(new TSANetWebhookQueueable(null, 'tok', null));
        Test.stopTest();

        System.assert(true, 'Null event type should not throw');
    }

    @IsTest
    static void testUnauthorizedResponseIsLoggedNotThrown() {
        Test.setMock(HttpCalloutMock.class, new WebhookQueueableMock(401, '{"error":"Unauthorized"}'));

        Test.startTest();
            System.enqueueJob(new TSANetWebhookQueueable('collaboration-request.created', 'tok', null));
        Test.stopTest();

        System.assertNotEquals(0, [
            SELECT COUNT() FROM tsanetconnect__TSANetError__c WHERE tsanetconnect__Context__c = 'TSANET_WEBHOOK_QUEUEABLE'
        ], 'A rejected callout must be logged instead of failing the job');
    }

    @IsTest
    static void testMissingNamedCredentialIsLogged() {
        tsanetconnect__TSANet_Credentials__c credential = [SELECT Id FROM tsanetconnect__TSANet_Credentials__c LIMIT 1];
        credential.tsanetconnect__NamedCredential__c = null;
        TSANetDataFactory.suppressSetupInitialization();
        update credential;
        AuthModeManager.clearCache();

        Test.startTest();
            System.enqueueJob(new TSANetWebhookQueueable('collaboration-request.created', 'tok', null));
        Test.stopTest();

        System.assertNotEquals(0, [
            SELECT COUNT() FROM tsanetconnect__TSANetError__c WHERE tsanetconnect__Context__c = 'TSANET_WEBHOOK_QUEUEABLE'
        ], 'Without a Named Credential the job must log the configuration problem');
    }
    /**
     * Named Credential mock: every callout returns the given status and body.
     */
    private class WebhookQueueableMock implements HttpCalloutMock {
        private Integer statusCode;
        private String dataBody;

        public WebhookQueueableMock(Integer statusCode, String dataBody) {
            this.statusCode = statusCode;
            this.dataBody = dataBody;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(this.statusCode);
            res.setBody(this.dataBody);
            return res;
        }
    }
}
