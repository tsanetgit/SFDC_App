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
    static void test_updateCredentials_and_updateToken() {
        User user = TSANetDataFactory.createAdminUser();

        System.runAs(user){
            TSANetCompanyInfo info = new TSANetCompanyInfo();
            info.user = new TSANetCompanyInfo.CompanyUser();
            info.user.email = 'test@gmail.com';
            info.company = new TSANetCompanyInfo.Company();
            info.company.id = 'COMP-123';
            info.company.name = 'Acme Inc';

            String token = '';
            for (Integer i = 0; i < 220; i++) {
                token += 'A';
            }

            Test.startTest();
            CredentialManager.updateCredentials(info);
            CredentialManager.updateToken(token);
            Test.stopTest();

            tsanetconnect__TSANet_Credentials__c updated = [
                SELECT Id,
                       tsanetconnect__CompanyName__c,
                       tsanetconnect__CompanyId__c,
                       tsanetconnect__AccessTokenPart1__c,
                       tsanetconnect__AccessTokenPart2__c
                FROM tsanetconnect__TSANet_Credentials__c
                LIMIT 1
            ];

            System.assertEquals('Acme Inc', updated.tsanetconnect__CompanyName__c);
            System.assertEquals('COMP-123', updated.tsanetconnect__CompanyId__c);
            System.assertNotEquals(null, updated.tsanetconnect__AccessTokenPart1__c);
            System.assertEquals(true, updated.tsanetconnect__AccessTokenPart1__c.length() <= 175);
            System.assertEquals(true, (updated.tsanetconnect__AccessTokenPart2__c == null) || updated.tsanetconnect__AccessTokenPart2__c.length() >= 0);
            System.assertEquals(token, (updated.tsanetconnect__AccessTokenPart1__c == null ? '' : updated.tsanetconnect__AccessTokenPart1__c) +
                                     (updated.tsanetconnect__AccessTokenPart2__c == null ? '' : updated.tsanetconnect__AccessTokenPart2__c));
        }
    }
}