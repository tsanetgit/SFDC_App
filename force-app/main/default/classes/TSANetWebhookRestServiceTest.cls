/** Unit tests for TSANetWebhookRestService — publishes a platform event and enqueues processing. */
@IsTest
public class TSANetWebhookRestServiceTest {

    @TestSetup
    static void testSetup() {
        User u = TSANetDataFactory.createAdminUser();
        System.runAs(u) {
            TSANetDataFactory.createCredentials();
        }
    }

    @IsTest
    static void testHandleGet() {
        Test.startTest();
            String result = TSANetWebhookRestService.handleGet();
        Test.stopTest();

        Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assertEquals('ok', payload.get('status'), 'Health check should return ok status');
        System.assertNotEquals(null, payload.get('timestamp'), 'Health check should include a timestamp');
    }

    @IsTest
    static void testHandleEventPublishesPlatformEventAndEnqueues() {
        setupRequest('{"eventType":"collaboration-request.created","requestToken":"tok1","noteToken":null,"timestamp":"2024-01-01T00:00:00Z"}');
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, '{}', null));

        Test.startTest();
            TSANetWebhookRestService.handleEvent();
            Integer published = Limits.getDmlStatements();
            Integer jobs = Limits.getQueueableJobs();
            Integer statusCode = RestContext.response.statusCode;
        Test.stopTest();

        System.assertEquals(200, statusCode, 'Expected 200 status');
        System.assertEquals(1, published, 'The inbound webhook must be published as a platform event');
        System.assertEquals(1, jobs, 'REST must enqueue processing as the Integration User');
    }

    @IsTest
    static void testHandleEventWithBlankToken() {
        setupRequest('{"eventType":"collaboration-request.created","requestToken":"","noteToken":null,"timestamp":"2024-01-01T00:00:00Z"}');

        Test.startTest();
            TSANetWebhookRestService.handleEvent();
            System.assertEquals(0, Limits.getDmlStatements(), 'An event without a token is not worth publishing');
            System.assertEquals(0, Limits.getQueueableJobs(), 'An event without a token must not enqueue');
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode, 'Blank requestToken should still return 200');
    }

    @IsTest
    static void testHandleEventWithInvalidJson() {
        setupRequest('not-valid-json');

        Test.startTest();
            TSANetWebhookRestService.handleEvent();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode, 'Invalid JSON should be caught and still return 200');
        System.assertEquals(1, [
            SELECT COUNT()
            FROM tsanetconnect__TSANetError__c
            WHERE tsanetconnect__Context__c = 'TSANET_WEBHOOK_REST'
        ], 'Parse errors must be written with ErrorLogger now that REST runs as the Integration User');
    }

    @IsTest
    static void testHandleCloudEventCreatedPublishesPlatformEvent() {
        setupRequest(
            '{"specversion":"1.0","id":"evt-1","source":"https://connect2.tsanet.org",'
            + '"type":"org.tsanet.connect.collaboration-request.created",'
            + '"data":{"requestToken":"tok1"}}'
        );
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, '{}', null));

        Test.startTest();
            TSANetWebhookRestService.handleEvent();
            Integer published = Limits.getDmlStatements();
            Integer jobs = Limits.getQueueableJobs();
            Integer statusCode = RestContext.response.statusCode;
        Test.stopTest();

        System.assertEquals(200, statusCode, 'Expected 200 status');
        System.assertEquals(1, published, 'A V2 CloudEvent with requestToken must be published');
        System.assertEquals(1, jobs, 'A V2 CloudEvent must enqueue processing');
    }

    @IsTest
    static void testHandleCloudEventNotePublishesPlatformEvent() {
        setupRequest(
            '{"specversion":"1.0","type":"org.tsanet.connect.collaboration-request.note.created",'
            + '"data":{"requestToken":"tok1","noteToken":"note1"}}'
        );
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, '{}', null));

        Test.startTest();
            TSANetWebhookRestService.handleEvent();
            Integer published = Limits.getDmlStatements();
            Integer jobs = Limits.getQueueableJobs();
        Test.stopTest();

        System.assertEquals(1, published, 'A V2 note CloudEvent must be published');
        System.assertEquals(1, jobs, 'A V2 note CloudEvent must enqueue processing');
    }

    @IsTest
    static void testHandleCloudEventBlankRequestTokenDoesNotPublish() {
        setupRequest(
            '{"specversion":"1.0","type":"org.tsanet.connect.collaboration-request.created",'
            + '"data":{"requestToken":""}}'
        );

        Test.startTest();
            TSANetWebhookRestService.handleEvent();
            System.assertEquals(0, Limits.getDmlStatements(), 'Blank CloudEvent requestToken must not publish');
            System.assertEquals(0, Limits.getQueueableJobs(), 'Blank CloudEvent requestToken must not enqueue');
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode, 'Blank CloudEvent token should still return 200');
    }

    private static void setupRequest(String body){
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/tsanetconnect/webhook';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(body);

        RestContext.request = req;
        RestContext.response = new RestResponse();
    }
}
