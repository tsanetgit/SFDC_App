@IsTest
public class ConfigManagerTest {
    
    @testSetup static void testSetup() {
        User user = TSANetDataFactory.createAdminUser();
        System.runAs(user){
            TSANetDataFactory.createCredentials();
            Account account = TSANetDataFactory.createAccount();
            Contact contact = TSANetDataFactory.createContact(account.Id);
            Case caseRecord = TSANetDataFactory.createCase(account.Id, contact.Id);
            TSANetDataFactory.createTSANetCase(caseRecord.Id);
        }
	}

    private class TSANetHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);

            // Імітуємо відповіді TSANet API
            if (req.getEndpoint().contains('token')) {
                res.setBody('{"access_token":"TEST_TOKEN"}');
            } else {
                res.setBody('{"company":{"id":"COMPANY_123","name":"Test Company"}}');
            }
            return res;
        }
    }

    @IsTest
    static void test_updateTSANetCredentials_success() {

        Test.setMock(HttpCalloutMock.class, new TSANetHttpMock());

        Test.startTest();
        Boolean result = ConfigManager.updateTSANetCredentials();
        Test.stopTest();

        // Assert
        System.assertEquals(true, result);

        tsanetconnect__TSANet_Credentials__c updated = [
            SELECT tsanetconnect__CompanyId__c,
                   tsanetconnect__CompanyName__c,
                   tsanetconnect__Token__c
            FROM tsanetconnect__TSANet_Credentials__c
            LIMIT 1
        ];

        System.assertEquals('COMPANY_123', updated.tsanetconnect__CompanyId__c);
        System.assertEquals('Test Company', updated.tsanetconnect__CompanyName__c);
    }
}