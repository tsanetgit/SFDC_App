/** Unit tests for ConfigManager. */
@IsTest
public class ConfigManagerTest {

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

    /** Mock HTTP callout handler for ConfigManager tests. */
    private class TSANetHttpMock implements HttpCalloutMock {
        /** Returns a mock HTTP response for the given request.
         * @param req the HTTP request
         * @return simulated HTTP response
         */
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"company":{"id":"COMPANY_123","name":"Test Company"}}');
            return res;
        }
    }

    @IsTest
    static void test_updateTSANetCredentials_success() {

        Test.setMock(HttpCalloutMock.class, new TSANetHttpMock());

        Test.startTest();
        Boolean result = ConfigManager.updateTSANetCredentials();
        Test.stopTest();

        System.assertEquals(true, result);

        tsanetconnect__TSANet_Credentials__c updated = [
            SELECT tsanetconnect__CompanyId__c,
                   tsanetconnect__CompanyName__c
            FROM tsanetconnect__TSANet_Credentials__c
            LIMIT 1
        ];

        System.assertEquals('COMPANY_123', updated.tsanetconnect__CompanyId__c);
        System.assertEquals('Test Company', updated.tsanetconnect__CompanyName__c);
    }

    @IsTest
    static void test_updateTSANetCredentials_withoutNamedCredential() {
        // The trigger blocks deleting a primary credential, so clear the Named Credential instead.
        tsanetconnect__TSANet_Credentials__c credential = [SELECT Id FROM tsanetconnect__TSANet_Credentials__c LIMIT 1];
        credential.tsanetconnect__NamedCredential__c = null;
        TSANetDataFactory.suppressSetupInitialization();
        update credential;
        AuthModeManager.clearCache();

        Test.startTest();
        try {
            ConfigManager.updateTSANetCredentials();
            System.assert(false, 'A credential without a Named Credential must not attempt a callout');
        } catch (Exception e) {
            System.assert(e instanceof AuraHandledException, 'The UI must receive a handled configuration error');
        }
        Test.stopTest();
    }
}
