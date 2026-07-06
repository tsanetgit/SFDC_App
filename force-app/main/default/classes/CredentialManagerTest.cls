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
}
