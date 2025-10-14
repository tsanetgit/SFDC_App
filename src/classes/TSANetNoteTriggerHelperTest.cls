@isTest
public class TSANetNoteTriggerHelperTest {
    
    @testSetup static void testSetup() {
        
        tsanet_connect__TSANetConfiguration__c config = tsanet_connect__TSANetConfiguration__c.getOrgDefaults();
        config.tsanet_connect__IntegrationUser__c = UserInfo.getUserId();
        upsert config;
        
        tsanet_connect__TSANet_Credentials__c credentials = new tsanet_connect__TSANet_Credentials__c();
        credentials.tsanet_connect__UserName__c = 'username@gmail.com';
        credentials.tsanet_connect__Password__c = 'password111';
        credentials.tsanet_connect__Environment__c = 'dev';
        credentials.tsanet_connect__Token__c = 'token';
        credentials.tsanet_connect__isPrimary__c = true;
        insert credentials;

        Account account = new Account(Name = 'Test Account');
        insert account;
        
        Contact contact = new Contact(LastName = 'Test Contact', Email = 'test@gmail.com', Phone = 'Test Phone', accountId = account.Id);
        insert contact;
        
        Case caseRecord = new Case(
            ContactId = contact.Id,
            AccountId = account.Id,
            Subject = 'test',
            Status = 'Working',
            Origin = 'Phone');
        
        insert caseRecord;
        
        tsanet_connect__TSANetCase__c tsaNetCase = new tsanet_connect__TSANetCase__c(tsanet_connect__Token__c = 'test-token', tsanet_connect__CaseToken__c = 'test-token', tsanet_connect__Case__c = caseRecord.Id);
        insert tsaNetCase;
	}

    @isTest
    public static void createFeedItemsTest(){
        
        String json = '{ "id": 2650, "caseId": 2793, "creatorUsername": null, "creatorEmail": "John.Smith@cisco.com", "creatorName": "Test User", "summary": "Note integration1", "description": "testing note 32", "priority": "LOW", "status": "ENTERED", "token": "UgchTc38fDLexCJ63F", "createdAt": "2024-11-25T14:32:06.244Z", "updatedAt": "2024-11-25T14:32:06.244Z" }';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, json, null));
        Test.startTest();
        	tsanet_connect__TSANetNote__c note = new tsanet_connect__TSANetNote__c();
            note.tsanet_connect__TSANetCase__c = [SELECT Id FROM tsanet_connect__TSANetCase__c LIMIT 1].Id;
            note.tsanet_connect__Token__c = 'test_token';
            note.tsanet_connect__Summary__c = 'Summary';
            note.tsanet_connect__Description__c = '<strong>Description 1</strong>';
            note.tsanet_connect__Priority__c = 'LOW';
            note.tsanet_connect__Status__c = 'OPEN';
            note.tsanet_connect__CreatorUserName__c = 'test_creator';
            
            insert note;
        	update note;
        Test.stopTest();
    }
}