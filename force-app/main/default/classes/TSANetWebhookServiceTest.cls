/** Unit tests for TSANetWebhookService — covers register, get, delete, delivery log, and parseDateTime. */
@IsTest
public class TSANetWebhookServiceTest {

    private static final String REGISTER_RESPONSE = '{"id":42,"callbackUrl":"https://example.com/webhook","eventTypes":["collaboration-request.created","note.created"],"active":true,"secret":"whsec_test123","createdAt":"2024-07-01T10:00:00.000Z"}';
    private static final String LIST_RESPONSE = '[{"id":42,"callbackUrl":"https://example.com/webhook","eventTypes":["collaboration-request.created"],"active":true}]';
    private static final String DELIVERY_RESPONSE = '[{"id":1,"webhookId":42,"statusCode":200,"createdAt":"2024-07-01T12:00:00Z"}]';
    private static final String LOGIN_RESPONSE = '{"accessToken":"mock-token","tokenType":"bearer","expiresIn":3600}';

    @TestSetup
    static void testSetup() {
        User u = TSANetDataFactory.createAdminUser();
        System.runAs(u) {
            TSANetDataFactory.createCredentials();
        }
    }

    @IsTest
    static void testRegisterWebhook() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, REGISTER_RESPONSE, null));

        Test.startTest();
            String result = TSANetWebhookService.registerWebhook(
                'https://example.com/webhook',
                new String[]{ 'collaboration-request.created', 'note.created' },
                'mock-token'
            );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected response body');

        List<tsanetconnect__TSANetWebhook__c> webhooks = [
            SELECT Id, tsanetconnect__WebhookId__c, tsanetconnect__Secret__c, tsanetconnect__Active__c
            FROM tsanetconnect__TSANetWebhook__c
            WHERE tsanetconnect__WebhookId__c = 42
        ];
        System.assertEquals(1, webhooks.size(), 'Expected one webhook record');
        System.assertEquals(true, webhooks[0].tsanetconnect__Active__c, 'Webhook should be active');
    }

    @IsTest
    static void testGetWebhooks() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, LIST_RESPONSE, null));

        Test.startTest();
            String result = TSANetWebhookService.getWebhooks('mock-token');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected list response');
        System.assert(result.contains('"id":42'), 'Expected webhook id in response');
    }
/*
    @IsTest
    static void testDeleteWebhook() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(204, '', null));

        Test.startTest();
            TSANetWebhookService.deleteWebhook(42, 'mock-token');
        Test.stopTest();

        System.assert(true, 'Delete should complete without exception');
    }
        */

    @IsTest
    static void testDeleteWebhooksAsync() {
        Test.setMock(HttpCalloutMock.class, new WebhookServiceMock(LOGIN_RESPONSE));

        Test.startTest();
            TSANetWebhookService.deleteWebhooksAsync(new Set<Integer>{ 42, 43 });
        Test.stopTest();

        System.assert(true, 'Async delete should complete without exception');
    }

    @IsTest
    static void testRegisterWebhooksAsync() {
        tsanetconnect__TSANet_Credentials__c cred = [SELECT Id FROM tsanetconnect__TSANet_Credentials__c LIMIT 1];

        tsanetconnect__TSANetWebhook__c wh = new tsanetconnect__TSANetWebhook__c(
            tsanetconnect__CallbackUrl__c = 'https://example.com/services/apexrest/tsanetconnect/webhook',
            tsanetconnect__EventTypes__c = 'collaboration-request.created;note.created',
            tsanetconnect__TSANetCredential__c = cred.Id
        );
        insert wh;

        Test.setMock(HttpCalloutMock.class, new WebhookServiceMock(LOGIN_RESPONSE));

        Test.startTest();
            TSANetWebhookService.registerWebhooksAsync(new Set<Id>{ wh.Id });
        Test.stopTest();

        tsanetconnect__TSANetWebhook__c updated = [
            SELECT tsanetconnect__WebhookId__c, tsanetconnect__Active__c
            FROM tsanetconnect__TSANetWebhook__c
            WHERE Id = :wh.Id
        ];
        System.assertEquals(42, updated.tsanetconnect__WebhookId__c, 'WebhookId should be set from API');
    }
/*
    @IsTest
    static void testRegisterWebhooksAsyncNoToken() {
        delete [SELECT Id FROM tsanetconnect__TSANet_Credentials__c];

        tsanetconnect__TSANetWebhook__c wh = new tsanetconnect__TSANetWebhook__c(
            tsanetconnect__CallbackUrl__c = 'https://example.com/webhook',
            tsanetconnect__EventTypes__c = 'collaboration-request.created'
        );
        insert wh;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(401, '{"error":"Unauthorized"}', null));

        Test.startTest();
            try {
                TSANetWebhookService.registerWebhooksAsync(new Set<Id>{ wh.Id });
            } catch (Exception e) {
                // Expected — no credentials
            }
        Test.stopTest();

        System.assert(true, 'Missing credentials should be handled');
    }
*/
    @IsTest
    static void testGetDeliveryLog() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, DELIVERY_RESPONSE, null));

        Test.startTest();
            String result = TSANetWebhookService.getDeliveryLog(42, 'mock-token');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected delivery log response');
    }

    @IsTest
    static void testRegisterWebhookCreatedAtWithZ() {
        String body = '{"id":50,"callbackUrl":"https://example.com/wh","eventTypes":["note.created"],"active":true,"secret":"s","createdAt":"2024-07-01T10:00:00Z"}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, body, null));

        Test.startTest();
            TSANetWebhookService.registerWebhook('https://example.com/wh', new String[]{ 'note.created' }, 'tok');
        Test.stopTest();

        List<tsanetconnect__TSANetWebhook__c> webhooks = [SELECT tsanetconnect__CreatedAt__c FROM tsanetconnect__TSANetWebhook__c WHERE tsanetconnect__WebhookId__c = 50];
        System.assertNotEquals(null, webhooks[0].tsanetconnect__CreatedAt__c, 'CreatedAt with Z suffix should be parsed');
    }

    @IsTest
    static void testRegisterWebhookNullCreatedAt() {
        String body = '{"id":51,"callbackUrl":"https://example.com/wh","eventTypes":["note.created"],"active":false,"secret":"s","createdAt":null}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, body, null));

        Test.startTest();
            TSANetWebhookService.registerWebhook('https://example.com/wh', new String[]{ 'note.created' }, 'tok');
        Test.stopTest();

        List<tsanetconnect__TSANetWebhook__c> webhooks = [SELECT tsanetconnect__CreatedAt__c FROM tsanetconnect__TSANetWebhook__c WHERE tsanetconnect__WebhookId__c = 51];
        System.assertEquals(null, webhooks[0].tsanetconnect__CreatedAt__c, 'Null createdAt should remain null');
    }

    /** Multi-endpoint mock that handles login + webhook API calls. */
    private class WebhookServiceMock implements HttpCalloutMock {
        private String loginBody;

        public WebhookServiceMock(String loginBody) {
            this.loginBody = loginBody;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            if (req.getEndpoint().contains('/login')) {
                res.setStatusCode(200);
                res.setBody(this.loginBody);
            } else if (req.getMethod() == 'DELETE') {
                res.setStatusCode(204);
                res.setBody('');
            } else if (req.getMethod() == 'POST' && req.getEndpoint().contains('/webhooks')) {
                res.setStatusCode(200);
                res.setBody(REGISTER_RESPONSE);
            } else {
                res.setStatusCode(200);
                res.setBody('{}');
            }
            return res;
        }
    }
}
