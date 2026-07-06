/** Unit tests for TSANetResponseTriggerHelper — engineer field mapping on response insert. */
@IsTest
public class TSANetResponseTriggerHelperTest {

    @TestSetup
    static void testSetup() {
        User user = TSANetDataFactory.createAdminUser();
        System.runAs(user) {
            TSANetDataFactory.createCredentials();
            Account account = TSANetDataFactory.createAccount();
            Contact contact = TSANetDataFactory.createContact(account.Id);
            Case caseRecord = TSANetDataFactory.createCase(account.Id, contact.Id);

            tsanetconnect__TSANetCase__c tsaNetCase = new tsanetconnect__TSANetCase__c(
                tsanetconnect__Token__c = 'response-test-token',
                tsanetconnect__tsaNetCaseId__c = '2718',
                tsanetconnect__Case__c = caseRecord.Id
            );
            insert tsaNetCase;
        }
    }

    @IsTest
    static void testAssignEngineerInfo_copiesFieldsToParentCase() {
        tsanetconnect__TSANetCase__c parentCase = [
            SELECT Id, tsanetconnect__EngineerName__c, tsanetconnect__EngineerPhone__c, tsanetconnect__EngineerEmail__c
            FROM tsanetconnect__TSANetCase__c
            LIMIT 1
        ];

        System.assertEquals(null, parentCase.tsanetconnect__EngineerName__c);

        tsanetconnect__TSANetResponse__c response = new tsanetconnect__TSANetResponse__c(
            tsanetconnect__CaseId__c = '2718',
            tsanetconnect__tsaNetResponseId__c = '2136',
            tsanetconnect__Type__c = 'APPROVAL',
            tsanetconnect__EngineerName__c = 'John',
            tsanetconnect__EngineerPhone__c = '+1212',
            tsanetconnect__EngineerEmail__c = 'john@test.com'
        );

        Test.startTest();
        insert response;
        Test.stopTest();

        tsanetconnect__TSANetCase__c updatedCase = [
            SELECT tsanetconnect__EngineerName__c, tsanetconnect__EngineerPhone__c, tsanetconnect__EngineerEmail__c
            FROM tsanetconnect__TSANetCase__c
            WHERE Id = :parentCase.Id
        ];

        System.assertEquals('John', updatedCase.tsanetconnect__EngineerName__c);
        System.assertEquals('+1212', updatedCase.tsanetconnect__EngineerPhone__c);
        System.assertEquals('john@test.com', updatedCase.tsanetconnect__EngineerEmail__c);
    }
}
