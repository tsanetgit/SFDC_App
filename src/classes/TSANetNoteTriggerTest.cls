@isTest
public class TSANetNoteTriggerTest {
    
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
    public static void methodTest(){
        
        TSANetNote__c note = new TSANetNote__c(Summary__c = 'Test');
        
        insert note;
    }
}