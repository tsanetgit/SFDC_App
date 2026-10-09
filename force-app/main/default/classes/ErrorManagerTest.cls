@IsTest
public class ErrorManagerTest {

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

    @IsTest
    static void test_handleResponseErrors_status200_noException() {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setBody('{"ok":true}');

        Test.startTest();
        ErrorManager.handleResponseErrors(res);
        Test.stopTest();

        System.assert(true, 'No exception expected for 200');
    }

    @IsTest
    static void test_handleResponseErrors_invalidToken_throwsUnauthorized() {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(401);
        res.setBody('The authorization token provided was invalid.');

        Test.startTest();
        try {
            ErrorManager.handleResponseErrors(res);
            System.assert(false, 'Expected exception');
        } catch (ErrorManager.ErrorManagerException e) {
            System.assertEquals('Unauthorized', e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void test_handleResponseErrors_parsesJson_message() {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(400);
        res.setBody('{"message":"Bad request","detail":"ignored"}');

        Test.startTest();
        try {
            ErrorManager.handleResponseErrors(res);
            System.assert(false, 'Expected exception');
        } catch (ErrorManager.ErrorManagerException e) {
            System.assertEquals('Bad request', e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void test_handleResponseErrors_parsesJson_detail_whenMessageNull() {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(400);
        res.setBody('{"message":null,"detail":"Details here"}');

        Test.startTest();
        try {
            ErrorManager.handleResponseErrors(res);
            System.assert(false, 'Expected exception');
        } catch (ErrorManager.ErrorManagerException e) {
            System.assertEquals('Details here', e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void test_collectErrors_returnsLogs_forFailedUpserts() {
        // Make one valid and one invalid record to force an UpsertResult error
        List<Account> accs = new List<Account>{
            new Account(),                 // invalid (Name required)
            new Account(Name = 'Valid')    // valid
        };

        Database.UpsertResult[] results = Database.upsert(accs, false);

        Test.startTest();
        tsanetconnect__TSANetError__c[] logs =
            ErrorManager.collectErrors(results, (List<SObject>)accs, Account.Id);
        Test.stopTest();

        System.assert(logs.size() >= 1, 'Expected at least one error log');
    }

    @IsTest
    static void test_isUnauthorized() {
        System.assertEquals(true,
            ErrorManager.isUnauthorized('xxx The authorization token provided was invalid yyy'));
        System.assertEquals(false,
            ErrorManager.isUnauthorized('some other error'));
    }
}