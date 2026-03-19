@isTest
public class AccessDecisionUtilsTest {
	
    @isTest
    public static void verifyAccessDecisionTest(){
        Account account = new Account(Name='Test Account');
        AccessDecisionUtils.Decision decision = AccessDecisionUtils.verifyAccessDecision(new Account[]{ account }, AccessType.CREATABLE);
        AccessDecisionUtils.Decision access = new AccessDecisionUtils.Decision(false, null, null, null);
        System.assertEquals(true, decision.allowDML);
    }
    
    @isTest
    public static void verifyAccessDecisionUnsuccessTest(){
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        // This code runs as the system user 
        User u = new User(  Alias = 'standt', 
                            Email='standarduser@testorg.com',
                            EmailEncodingKey='UTF-8', 
                            LastName='Testing', 
                            LanguageLocaleKey='en_US',
                            LocaleSidKey='en_US',
                            ProfileId = [SELECT Id FROM Profile WHERE Name='Standard User'].Id,
                            TimeZoneSidKey='America/Los_Angeles',
                            UserName = uniqueUserName );

        System.runAs(u) {
            // This code runs as the standard user ( Campaign CRUD permission -> Read )
            Campaign campaign = new Campaign(Name = 'Test Campaign 1', IsActive = true);
            
            try { AccessDecisionUtils.verifyAccessDecision(new Campaign[]{ campaign }, AccessType.CREATABLE);
            } catch(Exception e){
                System.assertEquals('No access to entity: Campaign', e.getMessage());
            }
        }
    }
    
    @isTest
    public static void getErrorMessageTest(){
        Map<String, Set<String>> removedFields = new Map<String, Set<String>>();
        removedFields.put('Account', new Set<String>{'Name', 'Test__c'});
        String errorMessage = AccessDecisionUtils.getErrorMessage(removedFields);
        System.assertEquals('Account : Name, Test__c', errorMessage);
    }
}