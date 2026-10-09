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
            note.tsanetconnect__CreatorName__c = 'Tester';
            note.tsanetconnect__CreatedAt__c = DateTime.now();
            note.tsanetconnect__isCaseFeed__c = true;

            insert note;
        	update note;
        Test.stopTest();

        tsanetconnect__TSANetCase__c linkedCase = [
            SELECT tsanetconnect__Case__c FROM tsanetconnect__TSANetCase__c
            WHERE Id = :note.tsanetconnect__TSANetCase__c
        ];
        System.assertEquals(1, [
            SELECT COUNT() FROM FeedItem WHERE ParentId = :linkedCase.tsanetconnect__Case__c
        ], 'Inserting a note should post exactly one feed item on the linked Case');
    }

    @IsTest
    public static void createFeedItems_queueable_stampsIntegrationUser(){
        tsanetconnect__TSANetCase__c tsaNetCase = [
            SELECT Id, tsanetconnect__Case__c
            FROM tsanetconnect__TSANetCase__c
            LIMIT 1
        ];
        tsanetconnect__TSANet_Credentials__c cred = [
            SELECT tsanetconnect__IntegrationUser__c
            FROM tsanetconnect__TSANet_Credentials__c
            LIMIT 1
        ];

        Test.startTest();
        System.enqueueJob(new InsertNoteJob(tsaNetCase.Id));
        Test.stopTest();

        FeedItem feedItem = [
            SELECT CreatedById, Title
            FROM FeedItem
            WHERE ParentId = :tsaNetCase.tsanetconnect__Case__c
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals(cred.tsanetconnect__IntegrationUser__c, feedItem.CreatedById,
            'Background FeedItems must be authored as the Integration User');
        System.assertEquals('TSANet Note - queueable-feed-token', feedItem.Title,
            'Queueable note insert should still post a FeedItem');
        if(Schema.SObjectType.FeedItem.fields.getMap().containsKey('Visibility')){
            Id feedItemId = feedItem.Id;
            feedItem = Database.query('SELECT Visibility FROM FeedItem WHERE Id = :feedItemId LIMIT 1');
            System.assertEquals('InternalUsers', feedItem.get('Visibility'),
                'Standard users must post FeedItems as InternalUsers');
        }
    }

    /** Verifies Company Name, Type, and Direction are omitted from the note FeedItem body. */
    @IsTest
    public static void createFeedItems_omitsCompanyNameTypeAndDirection(){
        tsanetconnect__TSANetCase__c tsaNetCase = [SELECT Id, tsanetconnect__Case__c FROM tsanetconnect__TSANetCase__c LIMIT 1];

        Test.startTest();
            insert new tsanetconnect__TSANetNote__c(
                tsanetconnect__TSANetCase__c = tsaNetCase.Id,
                tsanetconnect__Token__c = 'type-direction-token',
                tsanetconnect__Summary__c = 'Summary',
                tsanetconnect__CreatorName__c = 'Tester',
                tsanetconnect__CompanyName__c = 'Test Company 3',
                tsanetconnect__CreatedAt__c = DateTime.now(),
                tsanetconnect__Type__c = 'USER_PUBLIC',
                tsanetconnect__Direction__c = 'OUTBOUND',
                tsanetconnect__isCaseFeed__c = true
            );
        Test.stopTest();

        FeedItem feedItem = [SELECT Body FROM FeedItem WHERE ParentId = :tsaNetCase.tsanetconnect__Case__c LIMIT 1];
        System.assert(feedItem.Body.contains('Created By: Tester'), 'Body should still include the creator: ' + feedItem.Body);
        System.assert(!feedItem.Body.contains('Company Name:'), 'Body should omit company name: ' + feedItem.Body);
        System.assert(!feedItem.Body.contains('Type:'), 'Body should omit the note type: ' + feedItem.Body);
        System.assert(!feedItem.Body.contains('Direction:'), 'Body should omit the note direction: ' + feedItem.Body);
    }

    @IsTest
    public static void selector_returnsNoteByTokenAndFeedFields(){
        tsanetconnect__TSANetNote__c note = new tsanetconnect__TSANetNote__c(
            tsanetconnect__TSANetCase__c = [SELECT Id FROM tsanetconnect__TSANetCase__c LIMIT 1].Id,
            tsanetconnect__Token__c = 'selector-token',
            tsanetconnect__Summary__c = 'Summary',
            tsanetconnect__CreatedAt__c = DateTime.now(),
            tsanetconnect__isCaseFeed__c = true
        );
        insert note;

        tsanetconnect__TSANetNote__c byToken = TSANetNoteSelector.getByToken('selector-token');
        System.assertEquals(note.Id, byToken.Id, 'getByToken should return the inserted note');

        tsanetconnect__TSANetNote__c[] forFeed = TSANetNoteSelector.getForFeedItemBuild(new Set<Id>{ note.Id });
        System.assertEquals(1, forFeed.size(), 'getForFeedItemBuild should return the note');
        System.assertEquals(true, forFeed[0].tsanetconnect__isCaseFeed__c, 'Feed-item query should include isCaseFeed');
    }

    /** Historical notes (or notes without CreatedAt) are stamped isNotified on insert. */
    @IsTest
    public static void markStaleNotesAsNotified_onInsert(){
        Id tsaNetCaseId = [SELECT Id FROM tsanetconnect__TSANetCase__c LIMIT 1].Id;
        tsanetconnect__TSANetNote__c staleNote = buildNote(tsaNetCaseId, 'stale-token', DateTime.now().addDays(-1));
        tsanetconnect__TSANetNote__c noDateNote = buildNote(tsaNetCaseId, 'nodate-token', null);

        Test.startTest();
            insert new List<tsanetconnect__TSANetNote__c>{ staleNote, noDateNote };
        Test.stopTest();

        Map<String, tsanetconnect__TSANetNote__c> byToken = queryNotesByToken(new Set<String>{ 'stale-token', 'nodate-token' });
        System.assertEquals(true, byToken.get('stale-token').tsanetconnect__isNotified__c, 'Note created yesterday must be marked notified');
        System.assertEquals(true, byToken.get('nodate-token').tsanetconnect__isNotified__c, 'Note without CreatedAt must be marked notified');
    }

    /** The update path (sync upsert of an existing row) re-stamps a historical note as notified. */
    @IsTest
    public static void markStaleNotesAsNotified_onUpdate(){
        Id tsaNetCaseId = [SELECT Id FROM tsanetconnect__TSANetCase__c LIMIT 1].Id;
        tsanetconnect__TSANetNote__c note = buildNote(tsaNetCaseId, 'update-token', DateTime.now().addDays(-3));
        insert note;

        Test.startTest();
            update new tsanetconnect__TSANetNote__c(
                Id = note.Id,
                tsanetconnect__isNotified__c = false,
                tsanetconnect__CreatedAt__c = DateTime.now().addDays(-3)
            );
        Test.stopTest();

        System.assertEquals(true, queryNotesByToken(new Set<String>{ 'update-token' }).get('update-token').tsanetconnect__isNotified__c,
            'Historical note updated via sync must be marked notified');
    }

    /** Today's notes stay eligible for the notification flow; an existing true flag is never reset. */
    @IsTest
    public static void markStaleNotesAsNotified_inMemoryRules(){
        tsanetconnect__TSANetNote__c freshNote = buildNote(null, 'fresh-token', DateTime.now());
        tsanetconnect__TSANetNote__c staleNote = buildNote(null, 'stale-token', DateTime.now().addDays(-1));
        tsanetconnect__TSANetNote__c flaggedNote = buildNote(null, 'flag-token', DateTime.now());
        flaggedNote.tsanetconnect__isNotified__c = true;

        TSANetNoteTriggerHelper.markStaleNotesAsNotified(new tsanetconnect__TSANetNote__c[]{ freshNote, staleNote, flaggedNote });

        System.assertEquals(false, freshNote.tsanetconnect__isNotified__c, 'Note created today must stay eligible for notification');
        System.assertEquals(true, staleNote.tsanetconnect__isNotified__c, 'Note created yesterday must be marked notified');
        System.assertEquals(true, flaggedNote.tsanetconnect__isNotified__c, 'Existing isNotified flag must be preserved');
    }

    /** Builds an unsaved note with the given token and TSANet CreatedAt. */
    private static tsanetconnect__TSANetNote__c buildNote(Id tsaNetCaseId, String token, DateTime createdAt){
        return new tsanetconnect__TSANetNote__c(
            tsanetconnect__TSANetCase__c = tsaNetCaseId,
            tsanetconnect__Token__c = token,
            tsanetconnect__Summary__c = 'Summary',
            tsanetconnect__CreatorName__c = 'Tester',
            tsanetconnect__CreatedAt__c = createdAt
        );
    }

    /** Queries isNotified__c for the given tokens, keyed by token. */
    private static Map<String, tsanetconnect__TSANetNote__c> queryNotesByToken(Set<String> tokens){
        Map<String, tsanetconnect__TSANetNote__c> byToken = new Map<String, tsanetconnect__TSANetNote__c>();
        for(tsanetconnect__TSANetNote__c note : [
            SELECT tsanetconnect__Token__c, tsanetconnect__isNotified__c
            FROM tsanetconnect__TSANetNote__c
            WHERE tsanetconnect__Token__c IN :tokens
        ]){
            byToken.put(note.tsanetconnect__Token__c, note);
        }
        return byToken;
    }

    /** Inserts a note inside a queueable so FeedItem creation runs in background context. */
    private class InsertNoteJob implements Queueable {
        private Id tsaNetCaseId;

        InsertNoteJob(Id tsaNetCaseId){
            this.tsaNetCaseId = tsaNetCaseId;
        }

        public void execute(QueueableContext context){
            insert new tsanetconnect__TSANetNote__c(
                tsanetconnect__TSANetCase__c = tsaNetCaseId,
                tsanetconnect__Token__c = 'queueable-feed-token',
                tsanetconnect__Summary__c = 'Summary',
                tsanetconnect__Description__c = '<strong>Body</strong>',
                tsanetconnect__CreatorName__c = 'Tester',
                tsanetconnect__CreatedAt__c = DateTime.now(),
                tsanetconnect__Priority__c = 'LOW',
                tsanetconnect__Status__c = 'OPEN',
                tsanetconnect__isCaseFeed__c = true
            );
        }
    }
}
