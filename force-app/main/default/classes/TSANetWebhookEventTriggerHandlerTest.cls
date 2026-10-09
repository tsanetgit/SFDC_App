/** Tests that publishing TSANetWebhookEvent__e notifies without enqueueing the queueable. */
@IsTest
public class TSANetWebhookEventTriggerHandlerTest {

    @TestSetup
    static void testSetup() {
        User admin = TSANetDataFactory.createAdminUser();
        System.runAs(admin) {
            TSANetDataFactory.createCredentials();
        }
    }

    @IsTest
    static void publishEvent_invokesSharedProcessor() {
        Test.startTest();
        EventBus.publish(new tsanetconnect__TSANetWebhookEvent__e(
            tsanetconnect__EventType__c = 'org.tsanet.connect.collaboration-request.note.created',
            tsanetconnect__RequestToken__c = 'pe-trigger-token',
            tsanetconnect__NoteToken__c = 'pe-note-token'
        ));
        Test.stopTest();

        System.assertEquals(0, [
            SELECT COUNT()
            FROM tsanetconnect__TSANetError__c
            WHERE tsanetconnect__Context__c IN ('PE_INVOCABLE_NOTIFIED', 'PE_TRIGGER_FIRED')
        ], 'PE trigger must not write breadcrumbs');
    }

    @IsTest
    static void emptyPayload_isNoOp() {
        TSANetWebhookEventTriggerHandler handler = new TSANetWebhookEventTriggerHandler();
        Test.startTest();
        handler.beforeInsert(new List<SObject>());
        handler.beforeUpdate(new Map<Id, SObject>(), new Map<Id, SObject>());
        handler.beforeDelete(new Map<Id, SObject>());
        handler.afterInsert(new Map<Id, SObject>());
        handler.afterUpdate(new Map<Id, SObject>(), new Map<Id, SObject>());
        handler.afterDelete(new Map<Id, SObject>());
        handler.afterUndelete(new Map<Id, SObject>());
        Test.stopTest();

        System.assertEquals(false, handler.isDisabled(), 'Webhook PE subscriber must stay enabled');
        System.assertEquals(0, Limits.getQueueableJobs(), 'Empty PE payload must not enqueue work');
    }

    @IsTest
    static void handleEvents_fromTriggerNew_doesNotEnqueue() {
        List<SObject> events = new List<SObject>{
            new tsanetconnect__TSANetWebhookEvent__e(
                tsanetconnect__EventType__c = 'note.created',
                tsanetconnect__RequestToken__c = 'direct-new-token',
                tsanetconnect__NoteToken__c = 'direct-note'
            )
        };

        Test.startTest();
        TSANetWebhookEventTriggerHandler.handleEvents(events);
        System.assertEquals(0, Limits.getQueueableJobs(), 'PE trigger must not enqueue the queueable');
        Test.stopTest();
    }
}
