/** Unit tests for InternalProcessManager. */
@IsTest
public class InternalProcessManagerTest {

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

    /** Mock HTTP callout handler for InternalProcessManager tests. */
    private class TSANetHttpMock implements HttpCalloutMock {
        /** HTTP status code the mock should return. */
        Integer statusCode;

        /** Successful 200 mock. */
        TSANetHttpMock() {
            this(200);
        }

        /** Mock that returns the given status code.
         * @param statusCode HTTP status to return
         */
        TSANetHttpMock(Integer statusCode) {
            this.statusCode = statusCode;
        }

        /** Returns a mock HTTP response for the given request.
         * @param req the HTTP request
         * @return simulated HTTP response
         */
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setHeader('Content-Type', 'application/json');

            if (statusCode != 200) {
                res.setBody('{"message":"Unauthorized"}');
                return res;
            }

            String endpoint = (req.getEndpoint() == null) ? '' : req.getEndpoint().toLowerCase();

            if (endpoint.contains('company') || endpoint.contains('me') || endpoint.contains('profile')) {
                res.setBody('{"company":{"id":"cmp_123","name":"Test Company"}}');
                return res;
            }

            if (endpoint.contains('webhook')) {
                res.setBody('[]');
                return res;
            }

            if (endpoint.contains('collaboration-requests')) {
                res.setBody('{"totalPages":1,"content":[]}');
                return res;
            }

            res.setBody('{}');
            return res;
        }
    }

    @IsTest
    static void test_scheduleTSANetJobs_creates4CronJobs() {
        tsanetconnect__TSANet_Credentials__c cred = [SELECT Id FROM tsanetconnect__TSANet_Credentials__c WITH USER_MODE LIMIT 1];

        Test.startTest();
        InternalProcessManager.scheduleTSANetJobs(cred.Id);
        Test.stopTest();

        List<CronTrigger> crons = [
            SELECT Id, State, CronJobDetail.Name
            FROM CronTrigger
            WHERE CronJobDetail.Name LIKE :('%TSANetScheduledJob - ' + String.valueOf(cred.Id) + '%')
            WITH USER_MODE
        ];

        System.assertEquals(4, crons.size(), 'Expected 4 scheduled TSANet jobs (:00/:15/:30/:45)');
    }

    @IsTest
    static void test_scheduleTSANetJobs_canRunTwice() {
        tsanetconnect__TSANet_Credentials__c cred = [SELECT Id FROM tsanetconnect__TSANet_Credentials__c WITH USER_MODE LIMIT 1];
        String jobFilter = '%TSANetScheduledJob - ' + String.valueOf(cred.Id) + '%';

        InternalProcessManager.scheduleTSANetJobs(cred.Id);
        System.assertEquals(4, [
            SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name LIKE :jobFilter
        ], 'Precondition: four jobs should exist');

        Test.startTest();
            InternalProcessManager.scheduleTSANetJobs(cred.Id);
        Test.stopTest();

        System.assertEquals(4, [
            SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name LIKE :jobFilter
        ], 'Re-activating primary must not create duplicate scheduled jobs');
    }

    @IsTest
    static void test_abortTSANetJobs_abortsAll() {
        tsanetconnect__TSANet_Credentials__c cred = [SELECT Id FROM tsanetconnect__TSANet_Credentials__c WITH USER_MODE LIMIT 1];

        InternalProcessManager.scheduleTSANetJobs(cred.Id);
        String jobFilter = '%TSANetScheduledJob - ' + String.valueOf(cred.Id) + '%';
        System.assertEquals(4, [
            SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name LIKE :jobFilter
        ], 'Precondition: the four sync jobs should be scheduled');

        Test.startTest();
        	InternalProcessManager.abortTSANetJobs(cred.Id);
        Test.stopTest();

        System.assertEquals(0, [
            SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name LIKE :jobFilter
        ], 'All TSANet sync jobs should have been aborted');
    }

    @IsTest
    static void test_syncAccount_updatesCredential() {
        tsanetconnect__TSANet_Credentials__c cred = [SELECT Id FROM tsanetconnect__TSANet_Credentials__c WITH USER_MODE LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new TSANetHttpMock());

        Test.startTest();
        	InternalProcessManager.syncAccount(cred.Id);
        Test.stopTest();

        tsanetconnect__TSANet_Credentials__c updated = [
            SELECT Id, tsanetconnect__CompanyId__c, tsanetconnect__CompanyName__c, tsanetconnect__isConnected__c
            FROM tsanetconnect__TSANet_Credentials__c
            WHERE Id = :cred.Id
            WITH USER_MODE
        ];

        System.assertEquals('cmp_123', updated.tsanetconnect__CompanyId__c, 'CompanyId should be set');
        System.assertEquals('Test Company', updated.tsanetconnect__CompanyName__c, 'CompanyName should be set');
        System.assertEquals(true, updated.tsanetconnect__isConnected__c, 'A successful probe should mark the credential connected');
    }

    @IsTest
    static void test_syncAccount_withoutNamedCredential_marksDisconnected() {
        tsanetconnect__TSANet_Credentials__c cred = [SELECT Id FROM tsanetconnect__TSANet_Credentials__c WITH USER_MODE LIMIT 1];
        cred.tsanetconnect__NamedCredential__c = null;
        cred.tsanetconnect__isConnected__c = true;
        TSANetDataFactory.suppressSetupInitialization();
        update cred;
        AuthModeManager.clearCache();

        Test.startTest();
            InternalProcessManager.syncAccount(cred.Id);
        Test.stopTest();

        System.assertEquals(false, [
            SELECT tsanetconnect__isConnected__c FROM tsanetconnect__TSANet_Credentials__c WHERE Id = :cred.Id
        ].tsanetconnect__isConnected__c, 'An unconfigured credential must be marked disconnected instead of calling out');
        System.assertEquals(1, [
            SELECT COUNT() FROM tsanetconnect__TSANetError__c WHERE tsanetconnect__Context__c = 'TSANET_ACCOUNT_SYNC'
        ], 'The missing Named Credential must be logged once');
    }

    @IsTest
    static void test_execute_runs_withoutErrors_andSchedulesJobs() {
        tsanetconnect__TSANet_Credentials__c cred = [SELECT Id FROM tsanetconnect__TSANet_Credentials__c WITH USER_MODE LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new TSANetHttpMock());

        Test.startTest();
        	InternalProcessManager.execute(cred);
        Test.stopTest();

        // verify scheduled jobs exist
        List<CronTrigger> crons = [
            SELECT Id, State, CronJobDetail.Name
            FROM CronTrigger
            WHERE CronJobDetail.Name LIKE :('%TSANetScheduledJob - ' + String.valueOf(cred.Id) + '%')
            WITH USER_MODE
        ];
        System.assertEquals(4, crons.size(), 'Expected 4 scheduled jobs after execute()');
        System.assertEquals(true, [
            SELECT tsanetconnect__isConnected__c FROM tsanetconnect__TSANet_Credentials__c WHERE Id = :cred.Id
        ].tsanetconnect__isConnected__c, 'A successful execute should mark the credential connected');
    }

    @IsTest
    static void test_execute_failedNamedCredential_doesNotScheduleJobs() {
        tsanetconnect__TSANet_Credentials__c cred = [SELECT Id FROM tsanetconnect__TSANet_Credentials__c WITH USER_MODE LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new TSANetHttpMock(401));

        Test.startTest();
            InternalProcessManager.execute(cred);
        Test.stopTest();

        System.assertEquals(false, [
            SELECT tsanetconnect__isConnected__c FROM tsanetconnect__TSANet_Credentials__c WHERE Id = :cred.Id
        ].tsanetconnect__isConnected__c, 'A failed Named Credential probe must leave the credential disconnected');
        System.assertEquals(0, [
            SELECT COUNT() FROM CronTrigger
            WHERE CronJobDetail.Name LIKE :('%TSANetScheduledJob - ' + String.valueOf(cred.Id) + '%')
        ], 'A failing probe must not schedule sync jobs');
        System.assertEquals(0, [
            SELECT COUNT() FROM AsyncApexJob WHERE ApexClass.Name = 'TSANetQueueableJob'
        ], 'A failing probe must not enqueue TSANetQueueableJob');
    }

    @IsTest
    static void test_insertPrimary_resetsConnectedUntilProbeSucceeds() {
        TSANetCredentialsHelper.initializeOnPrimaryChange = true;
        Test.setMock(HttpCalloutMock.class, new TSANetHttpMock());

        tsanetconnect__TSANet_Credentials__c cred = new tsanetconnect__TSANet_Credentials__c(
            tsanetconnect__NamedCredential__c = 'tsanetconnect__TSANetAPI',
            tsanetconnect__isPrimary__c = true,
            tsanetconnect__IntegrationUser__c = UserInfo.getUserId()
        );

        Test.startTest();
            insert cred;
            tsanetconnect__TSANet_Credentials__c inserted = [
                SELECT tsanetconnect__isConnected__c
                FROM tsanetconnect__TSANet_Credentials__c
                WHERE Id = :cred.Id
            ];
            System.assertEquals(false, inserted.tsanetconnect__isConnected__c, 'A new primary credential stays disconnected until the probe finishes');
        Test.stopTest();

        System.assertEquals(true, [
            SELECT tsanetconnect__isConnected__c FROM tsanetconnect__TSANet_Credentials__c WHERE Id = :cred.Id
        ].tsanetconnect__isConnected__c, 'A successful probe should mark the new credential connected');
    }

    @IsTest
    static void test_becomePrimary_resetsConnectedUntilProbeSucceeds() {
        TSANetCredentialsHelper.initializeOnPrimaryChange = true;
        Test.setMock(HttpCalloutMock.class, new TSANetHttpMock());

        tsanetconnect__TSANet_Credentials__c cred = new tsanetconnect__TSANet_Credentials__c(
            tsanetconnect__NamedCredential__c = 'tsanetconnect__TSANetAPI',
            tsanetconnect__isPrimary__c = false,
            tsanetconnect__isConnected__c = true,
            tsanetconnect__IntegrationUser__c = UserInfo.getUserId()
        );
        insert cred;

        Test.startTest();
            cred.tsanetconnect__isPrimary__c = true;
            update cred;
        Test.stopTest();

        tsanetconnect__TSANet_Credentials__c updated = [
            SELECT tsanetconnect__isConnected__c
            FROM tsanetconnect__TSANet_Credentials__c
            WHERE Id = :cred.Id
        ];
        System.assertEquals(true, updated.tsanetconnect__isConnected__c, 'Becoming primary should probe and mark the credential connected');
    }

    @IsTest
    static void test_updateAccessToken_namedCredential_reconnects() {
        TSANetDataFactory.createOAuthCredentials();
        Test.setMock(HttpCalloutMock.class, new TSANetHttpMock());

        Test.startTest();
            Boolean refreshed = AuthManager.updateAccessToken();
        Test.stopTest();

        System.assertEquals(true, refreshed, 'Named Credential reconnect should return true');
        System.assertEquals(true, [
            SELECT tsanetconnect__isConnected__c
            FROM tsanetconnect__TSANet_Credentials__c
            WHERE tsanetconnect__isPrimary__c = true
        ].tsanetconnect__isConnected__c, 'A successful Named Credential probe should mark the credential connected');
    }

    @IsTest
    static void test_updateAccessToken_failedProbe_marksDisconnected() {
        Test.setMock(HttpCalloutMock.class, new TSANetHttpMock(401));

        Test.startTest();
            AuthManager.updateAccessToken();
        Test.stopTest();

        System.assertEquals(false, [
            SELECT tsanetconnect__isConnected__c FROM tsanetconnect__TSANet_Credentials__c LIMIT 1
        ].tsanetconnect__isConnected__c, 'A failed probe should leave the primary credential disconnected');
    }

    @IsTest
    static void test_updateAccessToken_withoutNamedCredential_throws() {
        tsanetconnect__TSANet_Credentials__c cred = [SELECT Id FROM tsanetconnect__TSANet_Credentials__c WITH USER_MODE LIMIT 1];
        cred.tsanetconnect__NamedCredential__c = null;
        TSANetDataFactory.suppressSetupInitialization();
        update cred;

        Test.startTest();
        try {
            AuthManager.updateAccessToken();
            System.assert(false, 'Reconnecting without a Named Credential must be rejected up front');
        } catch (Exception e) {
            System.assert(e instanceof AuraHandledException, 'The UI must receive a handled configuration error');
        }
        Test.stopTest();
    }

    @IsTest
    static void test_scheduledJob_skipsWhenDisconnected() {
        tsanetconnect__TSANet_Credentials__c cred = [
            SELECT Id FROM tsanetconnect__TSANet_Credentials__c WITH USER_MODE LIMIT 1
        ];
        cred.tsanetconnect__isConnected__c = false;
        update cred;

        Test.startTest();
            new TSANetScheduledJob().execute(null);
        Test.stopTest();

        System.assertEquals(0, [
            SELECT COUNT() FROM AsyncApexJob WHERE ApexClass.Name = 'TSANetQueueableJob'
        ], 'A disconnected credential must not enqueue TSANetQueueableJob');
    }
}