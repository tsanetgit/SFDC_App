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

    // Helper: create a credentials record so CredentialManager.getCredentials() can return it.
    // Adjust required fields if your org has validations on tsanetconnect__TSANet_Credentials__c.
    private static tsanetconnect__TSANet_Credentials__c createCred(String token) {
        tsanetconnect__TSANet_Credentials__c credentials = new tsanetconnect__TSANet_Credentials__c();
        credentials.tsanetconnect__UserName__c = 'username@gmail.com';
        credentials.tsanetconnect__Password__c = 'password111';
        credentials.tsanetconnect__Token__c = 'token';
        credentials.tsanetconnect__isPrimary__c = true;
        credentials.tsanetconnect__Environment__c = 'dev';

        credentials.tsanetconnect__isPrimary__c = true;
        insert credentials;
        return credentials;
    }

    @IsTest
    static void test_handleResponseErrors_status200_noException() {
        createCred('tok');

        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setBody('{"ok":true}');

        Test.startTest();
        ErrorManager.handleResponseErrors(res);
        Test.stopTest();

        System.assert(true, 'No exception expected for 200');
    }

    @IsTest
    static void test_handleResponseErrors_invalidToken_clearsToken_andThrowsUnauthorized() {
        tsanetconnect__TSANet_Credentials__c cred = createCred('tok_to_clear');

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

        tsanetconnect__TSANet_Credentials__c updated = [
            SELECT Id, tsanetconnect__Token__c
            FROM tsanetconnect__TSANet_Credentials__c
            WHERE Id = :cred.Id
        ];
        System.assertEquals(null, updated.tsanetconnect__Token__c, 'Token should be cleared');
    }

    @IsTest
    static void test_handleResponseErrors_parsesJson_message() {
        createCred('tok');

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
        createCred('tok');

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