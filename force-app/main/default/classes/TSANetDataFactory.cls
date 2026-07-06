/**
 * Simple Test DataFactory (usable in @IsTest).
 * - Avoids SeeAllData
 * - Creates common records with sane defaults
 * - Supports optional overrides via a Map
 */
@IsTest
public class TSANetDataFactory {

    /** Creates and inserts an admin User with TSANet permissions.
     * @return the inserted User record
     */
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

    /** Seeds org-default TSANet token custom settings.
     * @param part1 first token part
     * @param part2 second token part
     */
    public static void seedTokens(String part1, String part2) {
        seedTokens(part1, part2, DateTime.now().addHours(1));
    }

    /** Seeds org-default TSANet token custom settings with expiry.
     * @param part1 first token part
     * @param part2 second token part
     * @param expiresAt when the token expires
     */
    public static void seedTokens(String part1, String part2, DateTime expiresAt) {
        tsanetconnect__TSANet_Tokens__c tokens = tsanetconnect__TSANet_Tokens__c.getOrgDefaults();
        if (tokens == null) {
            tokens = new tsanetconnect__TSANet_Tokens__c();
        }
        tokens.tsanetconnect__AccessTokenPart1__c = part1;
        tokens.tsanetconnect__AccessTokenPart2__c = part2;
        tokens.tsanetconnect__TokenExpiresAt__c = expiresAt;
        upsert tokens;
    }

    /** Creates and inserts a default TSANet credentials record.
     * @return the inserted credentials record
     */
    public static tsanetconnect__TSANet_Credentials__c createCredentials() {
        tsanetconnect__TSANet_Credentials__c credentials = new tsanetconnect__TSANet_Credentials__c();
        credentials.tsanetconnect__UserName__c = 'username@gmail.com';
        credentials.tsanetconnect__Password__c = 'password111';
        credentials.tsanetconnect__Environment__c = 'dev';
        credentials.tsanetconnect__isPrimary__c = true;
        insert credentials;
        seedTokens('token1', 'token2');
        return credentials;
    }

    /** Creates and inserts a test Account.
     * @return the inserted Account record
     */
    public static Account createAccount() {
        Account a = new Account(Name = 'Test Account');
        insert a;
        return a;
    }

    /** Creates and inserts a test Contact linked to the given Account.
     * @param accountId the parent Account Id
     * @return the inserted Contact record
     */
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

    /** Creates and inserts a test Case for the given Account and Contact.
     * @param accountId the Account Id
     * @param contactId the Contact Id
     * @return the inserted Case record
     */
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

    /** Creates and inserts a test TSANetCase linked to the given Case.
     * @param caseId the parent Case Id
     * @return the inserted TSANetCase record
     */
    public static tsanetconnect__TSANetCase__c createTSANetCase(Id caseId) {
        tsanetconnect__TSANetCase__c t = new tsanetconnect__TSANetCase__c(
            tsanetconnect__Token__c = 'test-token',
            tsanetconnect__Case__c  = caseId
        );
        insert t;
        return t;
    }
}