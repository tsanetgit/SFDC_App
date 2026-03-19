/**
 * Simple Test DataFactory (usable in @IsTest).
 * - Avoids SeeAllData
 * - Creates common records with sane defaults
 * - Supports optional overrides via a Map
 */
@IsTest
public class TSANetDataFactory {
    
    public static User createAdminUser() {
        Profile adminProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'System Administrator'
            LIMIT 1
        ];

        User u = new User(
            ProfileId = adminProfile.Id,
            Username = 'admin.' + System.currentTimeMillis() + '@test.com',
            Email = 'admin@test.com',
            LastName = 'Admin',
            Alias = 'admin',
            TimeZoneSidKey = 'Europe/Lisbon',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert u;
        
        // Query with namespace prefix for 2GP compatibility
        List<PermissionSet> psList = [SELECT Id FROM PermissionSet WHERE Name = 'TSANet_Connect_Permissions_Admin' LIMIT 1];
        if (psList.isEmpty()) {
            // Try with namespace prefix (2GP scratch org)
            psList = [SELECT Id FROM PermissionSet WHERE Name = 'tsanetconnect__TSANet_Connect_Permissions_Admin' LIMIT 1];
        }
        
        if (!psList.isEmpty()) {
            insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = psList[0].Id);
        }
        
        return u;
    }

    public static tsanetconnect__TSANet_Credentials__c createCredentials() {
        tsanetconnect__TSANet_Credentials__c credentials = new tsanetconnect__TSANet_Credentials__c();
        credentials.tsanetconnect__UserName__c = 'username@gmail.com';
        credentials.tsanetconnect__Password__c = 'password111';
        credentials.tsanetconnect__Environment__c = 'dev';
        credentials.tsanetconnect__AccessTokenPart1__c = 'token1';
        credentials.tsanetconnect__AccessTokenPart2__c = 'token2';
        credentials.tsanetconnect__isPrimary__c = true;
        insert credentials;
        return credentials;
    }
    
    public static Account createAccount() {
        Account a = new Account(Name = 'Test Account');
        insert a;
        return a;
    }

    public static Contact createContact(Id accountId) {
        Contact c = new Contact(
            LastName  = 'Test Contact',
            Email     = 'test@gmail.com',
            Phone     = 'Test Phone',
            AccountId = accountId
        );
        insert c;
        return c;
    }

    public static Case createCase(Id accountId, Id contactId) {
        Case cs = new Case(
            AccountId = accountId,
            ContactId = contactId,
            Subject   = 'test',
            Status    = 'Working',
            Origin    = 'Phone'
        );
        insert cs;
        return cs;
    }

    public static tsanetconnect__TSANetCase__c createTSANetCase(Id caseId) {
        tsanetconnect__TSANetCase__c t = new tsanetconnect__TSANetCase__c(
            tsanetconnect__Token__c = 'test-token',
            tsanetconnect__Case__c  = caseId
        );
        insert t;
        return t;
    }
}