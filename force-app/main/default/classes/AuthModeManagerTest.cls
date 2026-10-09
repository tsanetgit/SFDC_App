/** Unit tests for AuthModeManager — Named Credential resolution and the unconfigured case. */
@IsTest
public class AuthModeManagerTest {

    @IsTest
    static void testCredentialWithNamedCredentialIsUsable() {
        User admin = TSANetDataFactory.createAdminUser();
        System.runAs(admin) {
            TSANetDataFactory.createCredentials();

            Test.startTest();
                Boolean usesNamedCredential = AuthModeManager.usesNamedCredential();
            Test.stopTest();

            System.assertEquals(true, usesNamedCredential, 'A credential with a Named Credential must route through it');
            System.assertEquals('callout:tsanetconnect__TSANetAPI', AuthModeManager.getCalloutBase(), 'Callout base must prefix the Named Credential name');
        }
    }

    @IsTest
    static void testCredentialWithoutNamedCredentialIsNotUsable() {
        User admin = TSANetDataFactory.createAdminUser();
        System.runAs(admin) {
            TSANetDataFactory.createUnconfiguredCredentials();

            Test.startTest();
                Boolean usesNamedCredential = AuthModeManager.usesNamedCredential();
            Test.stopTest();

            System.assertEquals(false, usesNamedCredential, 'A credential without a Named Credential cannot make callouts');
            System.assertEquals(null, AuthModeManager.getCalloutBase(), 'An unconfigured credential has no callout base');
        }
    }

    @IsTest
    static void testBlankNamedCredentialOnRecordIsNotUsable() {
        tsanetconnect__TSANet_Credentials__c credentials = new tsanetconnect__TSANet_Credentials__c(
            tsanetconnect__isPrimary__c = true
        );

        Test.startTest();
            Boolean usesNamedCredential = AuthModeManager.usesNamedCredential(credentials);
        Test.stopTest();

        System.assertEquals(false, usesNamedCredential, 'A record without a Named Credential cannot make callouts');
        System.assertEquals(null, AuthModeManager.getCalloutBase(credentials), 'An incomplete record has no callout base');
    }

    @IsTest
    static void testCustomNamedCredentialKeepsUnqualifiedCalloutName() {
        tsanetconnect__TSANet_Credentials__c credentials = new tsanetconnect__TSANet_Credentials__c(
            tsanetconnect__NamedCredential__c = 'LocalAPI',
            tsanetconnect__isPrimary__c = true
        );

        Test.startTest();
            String calloutBase = AuthModeManager.getCalloutBase(credentials);
        Test.stopTest();

        System.assertEquals('callout:LocalAPI', calloutBase, 'Non-packaged Named Credentials must not receive the package namespace');
    }

    @IsTest
    static void testUnqualifiedPackagedNameResolvesToNamespacedCallout() {
        Test.startTest();
            String prodName = AuthModeManager.resolveNamedCredentialName('TSANetAPI');
            String devName = AuthModeManager.resolveNamedCredentialName('TSANetAPIDev');
            String betaName = AuthModeManager.resolveNamedCredentialName('TSANetAPIBeta');
            String testName = AuthModeManager.resolveNamedCredentialName('TSANetAPITest');
        Test.stopTest();

        System.assertEquals('tsanetconnect__TSANetAPI', prodName, 'Prod Named Credential must use the package namespace');
        System.assertEquals('tsanetconnect__TSANetAPIDev', devName, 'Dev Named Credential must use the package namespace');
        System.assertEquals('tsanetconnect__TSANetAPIBeta', betaName, 'Beta Named Credential must use the package namespace');
        System.assertEquals('tsanetconnect__TSANetAPITest', testName, 'Test Named Credential must use the package namespace');
    }

    @IsTest
    static void testPrefixedCustomNamedCredentialStripsPackageNamespace() {
        Test.startTest();
            String calloutName = AuthModeManager.resolveNamedCredentialName('tsanetconnect__LocalAPI');
        Test.stopTest();

        System.assertEquals('LocalAPI', calloutName, 'A custom name saved with the package prefix must be stripped');
    }

    @IsTest
    static void testMissingPrimaryCredentialIsNotUsable() {
        AuthModeManager.clearCache();

        Test.startTest();
            Boolean usesNamedCredential = AuthModeManager.usesNamedCredential();
        Test.stopTest();

        System.assertEquals(false, usesNamedCredential, 'Without a primary credential there is nothing to call out with');
    }
}
