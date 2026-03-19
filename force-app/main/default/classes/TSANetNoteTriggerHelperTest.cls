@isTest
public class TSANetNoteTriggerHelperTest {
    
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
    public static void createFeedItemsTest(){
        
        String json = '{ "id": 2650, "caseId": 2793, "creatorUsername": null, "creatorEmail": "John.Smith@cisco.com", "creatorName": "Test User", "summary": "Note integration1", "description": "testing note 32", "priority": "LOW", "status": "ENTERED", "token": "UgchTc38fDLexCJ63F", "createdAt": "2024-11-25T14:32:06.244Z", "updatedAt": "2024-11-25T14:32:06.244Z" }';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, json, null));
        Test.startTest();
        	tsanetconnect__TSANetNote__c note = new tsanetconnect__TSANetNote__c();
            note.tsanetconnect__TSANetCase__c = [SELECT Id FROM tsanetconnect__TSANetCase__c LIMIT 1].Id;
            note.tsanetconnect__Token__c = 'test_token';
            note.tsanetconnect__Summary__c = 'Summary';
            note.tsanetconnect__Description__c = '<strong>Description 1</strong>';
            note.tsanetconnect__Priority__c = 'LOW';
            note.tsanetconnect__Status__c = 'OPEN';
            
            insert note;
        	update note;
        Test.stopTest();
    }
}