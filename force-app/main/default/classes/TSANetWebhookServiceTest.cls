/** Unit tests for TSANetWebhookService — covers register, get, delete, delivery log, and parseDateTime. */
@IsTest
public class TSANetWebhookServiceTest {

    private static final String REGISTER_RESPONSE = '{"id":42,"callbackUrl":"https://example.com/webhook","eventTypes":["collaboration-request.created","note.created"],"active":true,"secret":"whsec_test123","createdAt":"2024-07-01T10:00:00.000Z"}';
    private static final String LIST_RESPONSE = '[{"id":42,"callbackUrl":"https://example.com/webhook","eventTypes":["collaboration-request.created"],"active":true}]';
    private static final String DELIVERY_RESPONSE = '[{"id":1,"webhookId":42,"statusCode":200,"createdAt":"2024-07-01T12:00:00Z"}]';
    private static final String LOGIN_RESPONSE = '{"accessToken":"mock-token","tokenType":"bearer","expiresIn":3600}';
    private static final String CLIENT_ID = 'connected-app-id';
    private static final String CLIENT_SECRET = 'connected-app-secret';

    @TestSetup
    static void testSetup() {
        User u = TSANetDataFactory.createAdminUser();
        System.runAs(u) {
            TSANetDataFactory.createCredentials();
        }
    }

    @IsTest
    static void testRegisterWebhookWithOAuthCallbackAuth() {
        tsanetconnect__TSANet_Credentials__c cred = [SELECT Id FROM tsanetconnect__TSANet_Credentials__c WITH USER_MODE LIMIT 1];
        CapturingWebhookMock mock = new CapturingWebhookMock(REGISTER_RESPONSE);
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
            String result = TSANetWebhookService.registerWebhook(
                'https://example.com/webhook',
                new String[]{ 'collaboration-request.created', 'note.created' },
                CLIENT_ID,
                CLIENT_SECRET,
                cred.Id
            );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected persisted webhook record Id');

        Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(mock.lastBody);
        Map<String, Object> auth = (Map<String, Object>) payload.get('callbackAuth');
        System.assertNotEquals(null, auth, 'Expected callbackAuth in the register payload');
        System.assertEquals('OAUTH2_CLIENT_CREDENTIALS', auth.get('type'), 'Auth type should be OAuth2 client credentials');
        System.assertEquals(true, String.valueOf(auth.get('oauth2TokenUrl')).endsWith('/services/oauth2/token'), 'Token URL should be this org token endpoint');
        System.assertEquals(CLIENT_ID, auth.get('oauth2ClientId'), 'Client Id should be forwarded');
        System.assertEquals(CLIENT_SECRET, auth.get('oauth2ClientSecret'), 'Client Secret should be forwarded');
        System.assertEquals('CLIENT_SECRET_BASIC', auth.get('oauth2ClientAuthenticationMethod'), 'Should send HTTP Basic client auth');
        System.assertEquals(false, auth.containsKey('oauth2Scope'), 'oauth2Scope must be omitted so the API uses Connected App scopes');
        System.assertEquals('V2', payload.get('payloadVersion'), 'OAuth register must send payloadVersion V2');
        System.assertEquals(true, mock.lastEndpoint.contains('/v2/webhooks'), 'OAuth register should POST to V2 webhooks');

        List<Object> eventTypes = (List<Object>) payload.get('eventTypes');
        System.assertEquals('org.tsanet.connect.collaboration-request.created', eventTypes[0], 'Created event must be the V2 CloudEvent type');
        System.assertEquals('org.tsanet.connect.collaboration-request.note.created', eventTypes[1], 'Note event must be the V2 CloudEvent type');

        tsanetconnect__TSANetWebhook__c webhook = [
            SELECT tsanetconnect__TSANetCredential__c
            FROM tsanetconnect__TSANetWebhook__c
            WHERE tsanetconnect__WebhookId__c = 42
            WITH USER_MODE
        ];
        System.assertEquals(cred.Id, webhook.tsanetconnect__TSANetCredential__c, 'Passed credential Id should be stored');
        System.assertEquals(webhook.Id, result, 'Return value should be the Salesforce record Id');
    }

    @IsTest
    static void testRegisterWebhookRequiresClientCredentials() {
        Boolean thrown = false;
        String message;
        try {
            TSANetWebhookService.registerWebhook(
                'https://example.com/webhook',
                new String[]{ 'note.created' },
                '',
                '',
                null
            );
        } catch (AuraHandledException e) {
            thrown = true;
            message = e.getMessage();
        }
        System.assertEquals(true, thrown, 'Blank client credentials must be rejected');
        System.assertEquals('Client Id and Client Secret are required.', message, 'Error should name the missing OAuth fields');
    }

    @IsTest
    static void testRegisterWebhookSurfacesApiError() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(400, '{"message":"bad callback"}', null));

        Boolean thrown = false;
        String message;
        try {
            TSANetWebhookService.registerWebhook(
                'https://example.com/webhook',
                new String[]{ 'note.created' },
                CLIENT_ID,
                CLIENT_SECRET,
                null
            );
        } catch (AuraHandledException e) {
            thrown = true;
            message = e.getMessage();
        }
        System.assertEquals(true, thrown, 'API errors should surface to the caller');
        System.assertEquals(true, String.isNotBlank(message), 'Error message should be readable');
    }

    @IsTest
    static void testGetCallbackUrlOptionsIsOrgDomainOnly() {
        Test.startTest();
            TSANetWebhookService.CallbackUrlOption[] options = TSANetWebhookService.getCallbackUrlOptions();
        Test.stopTest();

        System.assertEquals(1, options.size(), 'Only Org Domain is supported');
        System.assertEquals('Org Domain', options[0].label, 'Org Domain is the only option');
        System.assertEquals(true, options[0].value.endsWith('/services/apexrest/tsanetconnect/webhook'), 'Org Domain value is the Apex REST webhook URL');
        System.assertEquals(TSANetWebhookService.getDefaultCallbackUrl(), options[0].value, 'Option value matches getDefaultCallbackUrl');
    }

    @IsTest
    static void testGetWebhooks() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, LIST_RESPONSE, null));

        Test.startTest();
            String result = TSANetWebhookService.getWebhooks();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected list response');
        System.assert(result.contains('"id":42'), 'Expected webhook id in response');
    }

    @IsTest
    static void testDeleteWebhooksAsync() {
        Test.setMock(HttpCalloutMock.class, new WebhookServiceMock(LOGIN_RESPONSE));

        Test.startTest();
            TSANetWebhookService.deleteWebhooksAsync(new Set<Integer>{ 42, 43 });
        Test.stopTest();

        System.assert(true, 'Async delete should complete without exception');
    }

    @IsTest
    static void testGetDeliveryLog() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, DELIVERY_RESPONSE, null));

        Test.startTest();
            String result = TSANetWebhookService.getDeliveryLog(42);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected delivery log response');
    }

    @IsTest
    static void testRegisterWebhookCreatedAtWithZ() {
        String body = '{"id":50,"callbackUrl":"https://example.com/wh","eventTypes":["note.created"],"active":true,"secret":"s","createdAt":"2024-07-01T10:00:00Z"}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, body, null));

        Test.startTest();
            TSANetWebhookService.registerWebhook('https://example.com/wh', new String[]{ 'note.created' }, CLIENT_ID, CLIENT_SECRET, null);
        Test.stopTest();

        List<tsanetconnect__TSANetWebhook__c> webhooks = [SELECT tsanetconnect__CreatedAt__c FROM tsanetconnect__TSANetWebhook__c WHERE tsanetconnect__WebhookId__c = 50];
        System.assertNotEquals(null, webhooks[0].tsanetconnect__CreatedAt__c, 'CreatedAt with Z suffix should be parsed');
    }

    @IsTest
    static void testRegisterWebhookNullCreatedAt() {
        String body = '{"id":51,"callbackUrl":"https://example.com/wh","eventTypes":["note.created"],"active":false,"secret":"s","createdAt":null}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, body, null));

        Test.startTest();
            TSANetWebhookService.registerWebhook('https://example.com/wh', new String[]{ 'note.created' }, CLIENT_ID, CLIENT_SECRET, null);
        Test.stopTest();

        List<tsanetconnect__TSANetWebhook__c> webhooks = [SELECT tsanetconnect__CreatedAt__c FROM tsanetconnect__TSANetWebhook__c WHERE tsanetconnect__WebhookId__c = 51];
        System.assertEquals(null, webhooks[0].tsanetconnect__CreatedAt__c, 'Null createdAt should remain null');
    }

    @IsTest
    static void testToV2EventTypesLeavesCloudEventNamesUnchanged() {
        String[] mapped = TSANetWebhookService.toV2EventTypes(new String[]{
            'org.tsanet.connect.collaboration-request.created',
            ' note.created '
        });
        System.assertEquals('org.tsanet.connect.collaboration-request.created', mapped[0], 'Already-V2 names must pass through');
        System.assertEquals('org.tsanet.connect.collaboration-request.note.created', mapped[1], 'Trimmed V1 note name must map');
    }

    /** Captures the last POST body and endpoint so tests can assert the TSANet register payload. */
    private class CapturingWebhookMock implements HttpCalloutMock {
        public String lastBody;
        public String lastEndpoint;
        private String responseBody;

        public CapturingWebhookMock(String responseBody) {
            this.responseBody = responseBody;
        }

        public HTTPResponse respond(HTTPRequest req) {
            this.lastBody = req.getBody();
            this.lastEndpoint = req.getEndpoint();
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody(this.responseBody);
            return res;
        }
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
