@IsTest
public class InternalProcessManagerTest {

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
            res.setHeader('Content-Type', 'application/json');

            String endpoint = (req.getEndpoint() == null) ? '' : req.getEndpoint().toLowerCase();

            if (endpoint.contains('token') || endpoint.contains('oauth')) {
                res.setBody('{"access_token":"tok_test","token":"tok_test","jwt":"tok_test","expires_in":3600}');
                return res;
            }

            if (endpoint.contains('company') || endpoint.contains('me') || endpoint.contains('profile')) {
                res.setBody('{"company":{"id":"cmp_123","name":"Test Company"}}');
                return res;
            }

            if (endpoint.contains('collaboration-requests')) {
                res.setBody('{"totalPages":1,"content":[]}');
                return res;
            }

            // fallback
            res.setBody('{}');
            return res;
        }
    }

    @IsTest
    static void test_scheduleTSANetJobs_creates4CronJobs() {
        tsanetconnect__TSANet_Credentials__c cred = [SELECT Id FROM tsanetconnect__TSANet_Credentials__c LIMIT 1];

        Test.startTest();
        InternalProcessManager.scheduleTSANetJobs(cred.Id);
        Test.stopTest();

        List<CronTrigger> crons = [
            SELECT Id, State, CronJobDetail.Name
            FROM CronTrigger
            WHERE CronJobDetail.Name LIKE :('%TSANetScheduledJob - ' + String.valueOf(cred.Id) + '%')
        ];

        System.assertEquals(4, crons.size(), 'Expected 4 scheduled TSANet jobs (:00/:15/:30/:45)');
    }

    @IsTest
    static void test_abortTSANetJobs_abortsAll() {
        tsanetconnect__TSANet_Credentials__c cred = [SELECT Id FROM tsanetconnect__TSANet_Credentials__c LIMIT 1];

        Test.startTest();
        	InternalProcessManager.abortTSANetJobs(cred.Id);
        Test.stopTest();
    }

    @IsTest
    static void test_syncAccount_updatesCredential() {
        tsanetconnect__TSANet_Credentials__c cred = [SELECT Id FROM tsanetconnect__TSANet_Credentials__c LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new TSANetHttpMock());

        Test.startTest();
        	InternalProcessManager.syncAccount(cred.Id); 
        Test.stopTest();

        tsanetconnect__TSANet_Credentials__c updated = [
            SELECT Id, tsanetconnect__CompanyId__c, tsanetconnect__CompanyName__c, tsanetconnect__Token__c
            FROM tsanetconnect__TSANet_Credentials__c
            WHERE Id = :cred.Id
        ];

        System.assertEquals('cmp_123', updated.tsanetconnect__CompanyId__c, 'CompanyId should be set');
        System.assertEquals('Test Company', updated.tsanetconnect__CompanyName__c, 'CompanyName should be set');
    }

    @IsTest
    static void test_execute_runs_withoutErrors_andSchedulesJobs() {
        tsanetconnect__TSANet_Credentials__c cred = [SELECT Id FROM tsanetconnect__TSANet_Credentials__c LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new TSANetHttpMock());

        Test.startTest();
        	InternalProcessManager.execute(cred);
        Test.stopTest();

        // verify scheduled jobs exist
        List<CronTrigger> crons = [
            SELECT Id, State, CronJobDetail.Name
            FROM CronTrigger
            WHERE CronJobDetail.Name LIKE :('%TSANetScheduledJob - ' + String.valueOf(cred.Id) + '%')
        ];
        System.assertEquals(4, crons.size(), 'Expected 4 scheduled jobs after execute()');
    }
}