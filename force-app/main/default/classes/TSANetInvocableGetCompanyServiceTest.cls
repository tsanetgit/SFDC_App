@IsTest

public class TSANetInvocableGetCompanyServiceTest {

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
    public static void getCompaniesTest(){
        String body = '[ { "label": "Demo - VMware", "companyId": 1072, "departmentId": null } ]';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, body, null));
        Test.startTest();
        	TSANetInvocableGetCompanyService.TSANetCompanyResult[] data = TSANetInvocableGetCompanyService.getCompanies(new String[]{ 'Demo' });
        	System.assertEquals(true, data[0].companies.size() == 1);
        Test.stopTest();
    }
}