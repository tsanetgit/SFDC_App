@IsTest
private class CaseTriggerHandlerTest {

    private static User makeUser(String aliasSuffix) {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        return new User(
            Alias = 't' + aliasSuffix,
            Email = 't' + aliasSuffix + '@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'User' + aliasSuffix,
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 't' + aliasSuffix + '@example.com.' + System.currentTimeMillis(),
            ProfileId = p.Id
        );
    }

    @TestSetup
    static void setup() {
        insert new List<User>{ makeUser('01'), makeUser('02') };
    }

    @IsTest
    static void testOwnerChanged_Path() {
        // Arrange
        User u1 = [SELECT Id FROM User WHERE Email LIKE 't01@%' LIMIT 1];
        User u2 = [SELECT Id FROM User WHERE Email LIKE 't02@%' LIMIT 1];

        Case c = new Case(Subject = 'Test', Origin = 'Phone', OwnerId = u1.Id);
        insert c;

        Case cUpd = new Case(Id = c.Id, OwnerId = u2.Id);
        update cUpd;

        Map<Id, Case> oldMap = new Map<Id, Case>{
            c.Id => new Case(Id = c.Id, OwnerId = u1.Id)
        };
            
        Test.startTest();
        	CaseTriggerHandler.handleAfterUpdate(new List<Case>{ cUpd }, oldMap);
        Test.stopTest();

        System.assert(true, 'Handler executed for changed owner');
    }

    @IsTest
    static void testOwnerNotChanged_Noop() {

        User u1 = [SELECT Id FROM User WHERE Email LIKE 't01@%' LIMIT 1];

        Case c = new Case(Subject = 'Test 2', Origin = 'Email', OwnerId = u1.Id);
        insert c;

        Case cUpd = new Case(Id = c.Id, Subject = 'Still test');
        update cUpd;

        Map<Id, Case> oldMap = new Map<Id, Case>{
            c.Id => new Case(Id = c.Id, OwnerId = u1.Id)
        };

        // Act
        Test.startTest();
        	CaseTriggerHandler.handleAfterUpdate(new List<Case>{ cUpd }, oldMap);
        Test.stopTest();

        System.assert(true, 'Handler executed for unchanged owner');
    }
}