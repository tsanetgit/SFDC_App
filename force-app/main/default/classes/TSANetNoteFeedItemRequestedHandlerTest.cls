/** Tests for the leftover TSANetNoteFeedItemRequested__e subscriber. FeedItem insert now runs in the note trigger. */
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

    /** Publishing the leftover PE must not create FeedItems; the note trigger owns that DML. */
    @IsTest
    static void publishEvent_isNoOp(){
        tsanetconnect__TSANetCase__c tsaNetCase = [
            SELECT Id, tsanetconnect__Case__c
            FROM tsanetconnect__TSANetCase__c
            LIMIT 1
        ];

        Test.startTest();
        EventBus.publish(new tsanetconnect__TSANetNoteFeedItemRequested__e(
            tsanetconnect__NoteId__c = tsaNetCase.Id
        ));
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM FeedItem], 'PE subscriber must not insert FeedItems');
    }

    /** Empty event payload should be a safe no-op (no DML, no errors). */
    @IsTest
    static void emptyPayload_isNoOp(){
        TSANetNoteFeedItemRequestedHandler handler = new TSANetNoteFeedItemRequestedHandler();
        Test.startTest();
        handler.beforeInsert(new List<SObject>());
        handler.beforeUpdate(new Map<Id, SObject>(), new Map<Id, SObject>());
        handler.beforeDelete(new Map<Id, SObject>());
        handler.afterInsert(new Map<Id, SObject>());
        handler.afterUpdate(new Map<Id, SObject>(), new Map<Id, SObject>());
        handler.afterDelete(new Map<Id, SObject>());
        handler.afterUndelete(new Map<Id, SObject>());
        Test.stopTest();

        System.assertEquals(false, handler.isDisabled(), 'Handler stays enabled for the packaged trigger');
        System.assertEquals(0, [SELECT COUNT() FROM FeedItem], 'No FeedItems should have been created');
    }
}
