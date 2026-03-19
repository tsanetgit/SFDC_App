@isTest
public class TSANetNoteTriggerTest {
    
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
    public static void methodTest(){
        
        TSANetNote__c note = new TSANetNote__c(tsanetconnect__Summary__c = 'Test');
        
        insert note;
    }
}