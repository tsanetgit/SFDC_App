@IsTest

public class TSANetNoteTriggerTest {

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
    public static void methodTest(){

        TSANetNote__c note = new TSANetNote__c(tsanetconnect__Summary__c = 'Test');

        Test.startTest();
            insert note;
        Test.stopTest();

        System.assertNotEquals(null, note.Id, 'The trigger must not block a note without a parent case');
        System.assertEquals(1, [
            SELECT COUNT() FROM TSANetNote__c WHERE Id = :note.Id
        ], 'The note should have been persisted');
    }
}