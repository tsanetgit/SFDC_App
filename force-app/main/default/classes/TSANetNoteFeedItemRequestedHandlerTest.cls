/** Tests for the Platform Event subscriber that creates Chatter FeedItems off-Guest. */
@IsTest
public class TSANetNoteFeedItemRequestedHandlerTest {

    @TestSetup
    static void setup(){
        User user = TSANetDataFactory.createAdminUser();
        System.runAs(user){
            TSANetDataFactory.createCredentials();
            Account account = TSANetDataFactory.createAccount();
            Contact contact = TSANetDataFactory.createContact(account.Id);
            Case caseRecord = TSANetDataFactory.createCase(account.Id, contact.Id);
            TSANetDataFactory.createTSANetCase(caseRecord.Id);
        }
    }

    /**
     * Inserts a note, simulates a Guest publish (so the trigger publishes the PE
     * instead of inserting the FeedItem inline), and asserts that the subscriber
     * created a FeedItem on the parent Case after Test.stopTest.
     */
    @IsTest
    static void publishAndSubscribe_createsFeedItemOnParentCase(){
        tsanetconnect__TSANetCase__c tsaNetCase = [
            SELECT Id, tsanetconnect__Case__c
            FROM tsanetconnect__TSANetCase__c
            LIMIT 1
        ];
        tsanetconnect__TSANetNote__c note = new tsanetconnect__TSANetNote__c(
            tsanetconnect__TSANetCase__c = tsaNetCase.Id,
            tsanetconnect__Token__c = 'pe-handler-token',
            tsanetconnect__Summary__c = 'Summary',
            tsanetconnect__Description__c = '<strong>Body</strong>',
            tsanetconnect__CreatorName__c = 'Tester',
            tsanetconnect__CreatedAt__c = DateTime.now(),
            tsanetconnect__Priority__c = 'LOW',
            tsanetconnect__Status__c = 'OPEN'
        );

        Test.startTest();
        TSANetNoteTriggerHelper.treatAsGuestForTest = true;
        insert note;
        TSANetNoteTriggerHelper.treatAsGuestForTest = false;
        Test.stopTest();

        tsanetconnect__TSANetNote__c reloaded = [
            SELECT Id, tsanetconnect__FeedItemId__c
            FROM tsanetconnect__TSANetNote__c
            WHERE Id = :note.Id
        ];
        System.assertNotEquals(null, reloaded.tsanetconnect__FeedItemId__c,
            'Subscriber should have back-stamped FeedItemId__c on the note');

        FeedItem feedItem = [
            SELECT Id, Title
            FROM FeedItem
            WHERE Id = :reloaded.tsanetconnect__FeedItemId__c
        ];
        System.assertEquals('TSANet Note - pe-handler-token', feedItem.Title,
            'Subscriber should have inserted exactly one FeedItem on the parent Case');
    }

    /** Empty event payload should be a safe no-op (no DML, no errors). */
    @IsTest
    static void emptyPayload_isNoOp(){
        Test.startTest();
        new TSANetNoteFeedItemRequestedHandler().afterInsert(new Map<Id, SObject>());
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM FeedItem], 'No FeedItems should have been created');
    }
}
