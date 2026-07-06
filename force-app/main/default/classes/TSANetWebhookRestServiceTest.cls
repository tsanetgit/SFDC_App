/** Unit tests for TSANetWebhookRestService — covers GET, POST, and exception paths. */
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
    static void testHandleEventWithValidPayload() {
        String loginBody = '{"accessToken":"mock-token","tokenType":"bearer","expiresIn":3600}';
        String dataBody = '[{"id":1,"summary":"test","token":"tok1","customFields":[],"submittedBy":{},"caseNotes":[],"caseResponses":[]}]';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, loginBody, null));

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/tsanetconnect/webhook';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"eventType":"collaboration-request.created","requestToken":"tok1","noteToken":null,"timestamp":"2024-01-01T00:00:00Z"}');
        req.addHeader('X-Hub-Signature-256', 'sha256=abc');

        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
            TSANetWebhookRestService.handleEvent();
        Test.stopTest();

        System.assertEquals(200, res.statusCode, 'Expected 200 status');
    }

    @IsTest
    static void testHandleEventWithBlankToken() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/tsanetconnect/webhook';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"eventType":"collaboration-request.created","requestToken":"","noteToken":null,"timestamp":"2024-01-01T00:00:00Z"}');

        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
            TSANetWebhookRestService.handleEvent();
        Test.stopTest();

        System.assertEquals(200, res.statusCode, 'Blank requestToken should still return 200');
    }

    @IsTest
    static void testHandleEventWithInvalidJson() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/tsanetconnect/webhook';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('not-valid-json');

        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
            TSANetWebhookRestService.handleEvent();
        Test.stopTest();

        System.assertEquals(200, res.statusCode, 'Invalid JSON should be caught and still return 200');
    }
}
