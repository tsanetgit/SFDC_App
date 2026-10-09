@IsTest

public class CredentialManagerTest {

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
    static void test_updateCredentials() {
        User user = TSANetDataFactory.createAdminUser();

        System.runAs(user){
            TSANetCompanyInfo info = new TSANetCompanyInfo();
            info.user = new TSANetCompanyInfo.CompanyUser();
            info.user.email = 'test@gmail.com';
            info.company = new TSANetCompanyInfo.Company();
            info.company.id = 'COMP-123';
            info.company.name = 'Acme Inc';

            Test.startTest();
            CredentialManager.updateCredentials(info);
            Test.stopTest();

            tsanetconnect__TSANet_Credentials__c updated = [
                SELECT Id,
                       tsanetconnect__CompanyName__c,
                       tsanetconnect__CompanyId__c
                FROM tsanetconnect__TSANet_Credentials__c
                LIMIT 1
            ];

            System.assertEquals('Acme Inc', updated.tsanetconnect__CompanyName__c);
            System.assertEquals('COMP-123', updated.tsanetconnect__CompanyId__c);
        }
    }

    @IsTest
    static void test_getCredentialsIncludesIntegrationUser() {
        tsanetconnect__TSANet_Credentials__c stored = [
            SELECT tsanetconnect__IntegrationUser__c
            FROM tsanetconnect__TSANet_Credentials__c
            LIMIT 1
        ];
        tsanetconnect__TSANet_Credentials__c userMode = CredentialManager.getCredentials();

        System.assertNotEquals(null, stored.tsanetconnect__IntegrationUser__c,
            'DataFactory must stamp IntegrationUser__c on credentials');
        System.assertEquals(stored.tsanetconnect__IntegrationUser__c, userMode.tsanetconnect__IntegrationUser__c,
            'USER_MODE credential queries must select IntegrationUser__c');
    }

    @IsTest
    static void test_isConnected() {
        System.assertEquals(true, CredentialManager.isConnected(), 'Factory credentials default to connected');

        tsanetconnect__TSANet_Credentials__c cred = [
            SELECT Id FROM tsanetconnect__TSANet_Credentials__c WITH USER_MODE LIMIT 1
        ];
        cred.tsanetconnect__isConnected__c = false;
        update cred;

        System.assertEquals(false, CredentialManager.isConnected(), 'isConnected must follow the primary credential flag');
    }
}
