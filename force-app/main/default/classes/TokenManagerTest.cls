@IsTest
public class TokenManagerTest {

    @TestSetup
    static void testSetup() {
        User user = TSANetDataFactory.createAdminUser();
        System.runAs(user) {
            TSANetDataFactory.createCredentials();
        }
    }

    @IsTest
    static void test_updateToken_splitsAndReassembles() {
        User user = TSANetDataFactory.createAdminUser();

        System.runAs(user) {
            String token = '';
            for (Integer i = 0; i < 220; i++) {
                token += 'A';
            }

            Test.startTest();
            TokenManager.updateToken(token, 3600);
            Test.stopTest();

            tsanetconnect__TSANet_Tokens__c stored = tsanetconnect__TSANet_Tokens__c.getOrgDefaults();
            System.assertNotEquals(null, stored.tsanetconnect__AccessTokenPart1__c);
            System.assertEquals(true, stored.tsanetconnect__AccessTokenPart1__c.length() <= 175);
            System.assertEquals(token, stored.tsanetconnect__AccessTokenPart1__c +
                (stored.tsanetconnect__AccessTokenPart2__c == null ? '' : stored.tsanetconnect__AccessTokenPart2__c));
            System.assertNotEquals(null, stored.tsanetconnect__TokenExpiresAt__c);
        }
    }

    @IsTest
    static void test_clearToken_removesStoredParts() {
        User user = TSANetDataFactory.createAdminUser();

        System.runAs(user) {
            TSANetDataFactory.seedTokens('part1', 'part2');

            Test.startTest();
            TokenManager.clearToken();
            Test.stopTest();

            tsanetconnect__TSANet_Tokens__c stored = tsanetconnect__TSANet_Tokens__c.getOrgDefaults();
            System.assertEquals(null, stored.tsanetconnect__AccessTokenPart1__c);
            System.assertEquals(null, stored.tsanetconnect__AccessTokenPart2__c);
            System.assertEquals(null, stored.tsanetconnect__TokenExpiresAt__c);
        }
    }

    @IsTest
    static void test_getAccessToken_returnsStoredTokenWhenValid() {
        User user = TSANetDataFactory.createAdminUser();

        System.runAs(user) {
            TSANetDataFactory.seedTokens('stored', 'token', DateTime.now().addHours(1));

            Test.startTest();
            String token = TokenManager.getAccessToken();
            Test.stopTest();

            System.assertEquals('storedtoken', token);
        }
    }

    @IsTest
    static void test_getAccessToken_refreshesWhenExpired() {
        User user = TSANetDataFactory.createAdminUser();

        System.runAs(user) {
            TSANetDataFactory.seedTokens('expired', 'token', DateTime.now().addMinutes(-5));
            Test.setMock(HttpCalloutMock.class, new LoginMock());

            Test.startTest();
            String token = TokenManager.getAccessToken();

            // Token returned in memory but NOT yet persisted (safe for pre-callout use)
            System.assertEquals('fresh_token', token);
            tsanetconnect__TSANet_Tokens__c beforeCommit = tsanetconnect__TSANet_Tokens__c.getOrgDefaults();
            System.assertEquals('expired', beforeCommit.tsanetconnect__AccessTokenPart1__c);

            // Commit persists after callouts are done
            TokenManager.commitTokenIfPending();
            Test.stopTest();

            tsanetconnect__TSANet_Tokens__c stored = tsanetconnect__TSANet_Tokens__c.getOrgDefaults();
            System.assertEquals('fresh_token', stored.tsanetconnect__AccessTokenPart1__c);
        }
    }

    @IsTest
    static void test_refreshAccessToken_logsInWithoutDmlBeforeCallout() {
        User user = TSANetDataFactory.createAdminUser();

        System.runAs(user) {
            TSANetDataFactory.seedTokens('stale', 'token', DateTime.now().addHours(1));
            Test.setMock(HttpCalloutMock.class, new LoginMock());

            Test.startTest();
            String token = TokenManager.refreshAccessToken();
            Test.stopTest();

            System.assertEquals('fresh_token', token);
            tsanetconnect__TSANet_Tokens__c stored = tsanetconnect__TSANet_Tokens__c.getOrgDefaults();
            System.assertEquals('stale', stored.tsanetconnect__AccessTokenPart1__c,
                'Token must not be persisted until commitTokenIfPending()');
        }
    }

    /** Mock login response for refresh tests. */
    private class LoginMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"accessToken":"fresh_token","tokenType":"Bearer","expiresIn":3600}');
            return res;
        }
    }
}
