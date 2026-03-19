@isTest
public class TSANetInvocableRefreshCasesServiceTest {

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

    @isTest
    public static void closeRequestTest(){
        String body = '[ { "label": "Demo - VMware", "companyId": 1072, "departmentId": null } ]';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, body, null));
        Case sfCaseRecord = [SELECT Id FROM Case LIMIT 1];
        Test.startTest();
        TSANetInvocableRefreshCasesService.TSANetRefreshResult[] data = TSANetInvocableRefreshCasesService.refreshTSANetCases(new String[]{ sfCaseRecord.Id });
        Test.stopTest();
    }
}