@IsTest
public class TSANetNoteTriggerHelperTest {

     @TestSetup static void testSetup() {
		User user = TSANetDataFactory.createAdminUser();
        System.runAs(user){
            TSANetDataFactory.createCredentials();
            Account account = TSANetDataFactory.createAccount();
            Contact contact = TSANetDataFactory.createContact(account.Id);
            Case caseRecord = TSANetDataFactory.createCase(account.Id, contact.Id);
            TSANetDataFactory.createTSANetCase(caseRecord.Id);
        }
	}


    @IsTest
    public static void createFeedItemsTest(){

        String json = '{ "id": 2650, "caseId": 2793, "creatorUsername": null, "creatorEmail": "John.Smith@cisco.com", "creatorName": "Test User", "summary": "Note integration1", "description": "testing note 32", "priority": "LOW", "status": "ENTERED", "token": "UgchTc38fDLexCJ63F", "createdAt": "2024-11-25T14:32:06.244Z", "updatedAt": "2024-11-25T14:32:06.244Z" }';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, json, null));
        Test.startTest();
        	tsanetconnect__TSANetNote__c note = new tsanetconnect__TSANetNote__c();
            note.tsanetconnect__TSANetCase__c = [SELECT Id FROM tsanetconnect__TSANetCase__c LIMIT 1].Id;
            note.tsanetconnect__Token__c = 'test_token';
            note.tsanetconnect__Summary__c = 'Summary';
            note.tsanetconnect__Description__c = '<strong>Description 1</strong>';
            note.tsanetconnect__Priority__c = 'LOW';
            note.tsanetconnect__Status__c = 'OPEN';

            insert note;
        	update note;
        Test.stopTest();
    }

    /**
     * Guest path: when the trigger thinks the running user is a Site Guest,
     * createFeedItems publishes a Platform Event instead of inserting the FeedItem inline.
     * The subscriber then performs the insert when Test.stopTest delivers the event.
     */
    @IsTest
    public static void createFeedItems_guestPath_publishesPlatformEvent(){
        tsanetconnect__TSANetCase__c tsaNetCase = [
            SELECT Id, tsanetconnect__Case__c
            FROM tsanetconnect__TSANetCase__c
            LIMIT 1
        ];

        tsanetconnect__TSANetNote__c note = new tsanetconnect__TSANetNote__c(
            tsanetconnect__TSANetCase__c = tsaNetCase.Id,
            tsanetconnect__Token__c = 'guest-path-token',
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
            'Guest publish + subscriber should have back-stamped FeedItemId__c on the note');

        FeedItem feedItem = [
            SELECT Id, Title
            FROM FeedItem
            WHERE Id = :reloaded.tsanetconnect__FeedItemId__c
        ];
        System.assertEquals('TSANet Note - guest-path-token', feedItem.Title,
            'Guest publish + subscriber should have produced one FeedItem on the parent Case');
    }
}
