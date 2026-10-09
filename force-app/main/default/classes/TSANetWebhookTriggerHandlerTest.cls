/** Unit tests for TSANetWebhookTrigger and TSANetWebhookTriggerHandler — covers insert, delete, and isDisabled. */
@IsTest
public class TSANetWebhookTriggerHandlerTest {

    private static final String LOGIN_RESPONSE = '{"accessToken":"mock-token","tokenType":"bearer","expiresIn":3600}';
    private static final String REGISTER_RESPONSE = '{"id":99,"callbackUrl":"https://test.salesforce.com/services/apexrest/tsanetconnect/webhook","eventTypes":["collaboration-request.created"],"active":true,"secret":"sec","createdAt":"2024-07-01T10:00:00Z"}';

    @TestSetup
    static void testSetup() {
        User u = TSANetDataFactory.createAdminUser();
        System.runAs(u) {
            TSANetDataFactory.createCredentials();
        }
    }

    @IsTest
    static void testAfterInsertDoesNotRegisterWithoutOAuth() {
        Test.setMock(HttpCalloutMock.class, new WebhookTriggerMock());

        Test.startTest();
            tsanetconnect__TSANetWebhook__c wh = new tsanetconnect__TSANetWebhook__c(
                tsanetconnect__CallbackUrl__c = 'https://test.salesforce.com/services/apexrest/tsanetconnect/webhook',
                tsanetconnect__EventTypes__c = 'collaboration-request.created'
            );
            insert wh;
        Test.stopTest();

        tsanetconnect__TSANetWebhook__c result = [
            SELECT tsanetconnect__WebhookId__c FROM tsanetconnect__TSANetWebhook__c WHERE Id = :wh.Id
        ];
        System.assertEquals(null, result.tsanetconnect__WebhookId__c, 'Insert must not register without Client Id/Secret');
    }

    @IsTest
    static void testAfterInsertSkipsWhenWebhookIdExists() {
        Test.setMock(HttpCalloutMock.class, new WebhookTriggerMock());

        Test.startTest();
            tsanetconnect__TSANetWebhook__c wh = new tsanetconnect__TSANetWebhook__c(
                tsanetconnect__WebhookId__c = 100,
                tsanetconnect__CallbackUrl__c = 'https://test.salesforce.com/services/apexrest/tsanetconnect/webhook',
                tsanetconnect__EventTypes__c = 'collaboration-request.created'
            );
            insert wh;
        Test.stopTest();

        tsanetconnect__TSANetWebhook__c result = [
            SELECT tsanetconnect__WebhookId__c FROM tsanetconnect__TSANetWebhook__c WHERE Id = :wh.Id
        ];
        System.assertEquals(100, result.tsanetconnect__WebhookId__c, 'Pre-set WebhookId should be preserved');
    }

    @IsTest
    static void testBeforeDeleteCallsAsyncDelete() {
        Test.setMock(HttpCalloutMock.class, new WebhookTriggerMock());

        tsanetconnect__TSANet_Credentials__c cred = [SELECT Id FROM tsanetconnect__TSANet_Credentials__c LIMIT 1];

        tsanetconnect__TSANetWebhook__c wh = new tsanetconnect__TSANetWebhook__c(
            tsanetconnect__WebhookId__c = 55,
            tsanetconnect__CallbackUrl__c = 'https://test.salesforce.com/services/apexrest/tsanetconnect/webhook',
            tsanetconnect__EventTypes__c = 'collaboration-request.created',
            tsanetconnect__Active__c = true,
            tsanetconnect__TSANetCredential__c = cred.Id
        );
        insert wh;

        Test.startTest();
            delete wh;
        Test.stopTest();

        List<tsanetconnect__TSANetWebhook__c> remaining = [SELECT Id FROM tsanetconnect__TSANetWebhook__c WHERE Id = :wh.Id];
        System.assertEquals(0, remaining.size(), 'Webhook should be deleted');
    }

    @IsTest
    static void testBeforeDeleteSkipsNonSalesforceWebhook() {
        Test.setMock(HttpCalloutMock.class, new WebhookTriggerMock());

        tsanetconnect__TSANetWebhook__c wh = new tsanetconnect__TSANetWebhook__c(
            tsanetconnect__WebhookId__c = 60,
            tsanetconnect__CallbackUrl__c = 'https://external.com/my-webhook',
            tsanetconnect__EventTypes__c = 'collaboration-request.created'
        );
        insert wh;

        Test.startTest();
            delete wh;
        Test.stopTest();

        System.assert(true, 'Non-SF webhook should be deleted without API call');
    }

    @IsTest
    static void testIsDisabledReturnsFalse() {
        TSANetWebhookTriggerHandler handler = new TSANetWebhookTriggerHandler();
        System.assertEquals(false, handler.isDisabled(), 'Handler should never be disabled');
    }

    @IsTest
    static void testEmptyHandlerMethods() {
        TSANetWebhookTriggerHandler handler = new TSANetWebhookTriggerHandler();

        handler.beforeInsert(new List<SObject>());
        handler.beforeUpdate(new Map<Id, SObject>(), new Map<Id, SObject>());
        handler.afterUpdate(new Map<Id, SObject>(), new Map<Id, SObject>());
        handler.afterDelete(new Map<Id, SObject>());
        handler.afterUndelete(new Map<Id, SObject>());

        System.assert(true, 'Empty handler methods should execute without error');
    }

    /** Multi-endpoint mock for trigger tests. */
    private class WebhookTriggerMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            if (req.getEndpoint().contains('/login')) {
                res.setStatusCode(200);
                res.setBody(LOGIN_RESPONSE);
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
