@IsTest
public class TSANetHelperTest {

    @TestSetup
    static void testSetup() {
        User user = TSANetDataFactory.createAdminUser();
        System.runAs(user){
            Account account = TSANetDataFactory.createAccount();
            Contact contact = TSANetDataFactory.createContact(account.Id);
            TSANetDataFactory.createCase(account.Id, contact.Id);
        }
    }

    @IsTest
    public static void stripHtmlTagsTest(){
        String text = TSANetHelper.stripHtmlTags('<b>test</b>');
        System.assertEquals('test', text);
    }

    @IsTest
    public static void createCaseFeedItem_insertsWhenCreatable(){
        Case caseRecord = [SELECT Id FROM Case LIMIT 1];
        Map<String, Object> response = new Map<String, Object>{
            'submittedBy' => new Map<String, Object>{
                'firstName' => 'John',
                'lastName' => 'Smith',
                'email' => 'john@example.com',
                'phone' => '555',
                'phoneCountryCode' => 'US',
                'city' => 'Austin'
            },
            'submitCompanyName' => 'Acme',
            'receiveCompanyName' => 'Partner',
            'submitterCaseNumber' => '00001001',
            'summary' => 'Summary',
            'description' => 'Description',
            'priority' => 'LOW',
            'status' => 'OPEN',
            'createdAt' => '2024-07-16T16:15:10Z',
            'priorityNote' => '<p>Priority 3</p>'
        };

        Test.startTest();
        TSANetHelper.createCaseFeedItem(caseRecord.Id, response);
        Test.stopTest();

        System.assertEquals(1, [
            SELECT COUNT() FROM FeedItem WHERE ParentId = :caseRecord.Id
        ], 'createCaseFeedItem should insert one FeedItem when the user can create Chatter');
    }

    @IsTest
    public static void createCaseFeedItem_skipsNullCase(){
        Test.startTest();
        TSANetHelper.createCaseFeedItem(null, new Map<String, Object>());
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM FeedItem], 'Null Case Id must not insert a FeedItem');
    }
}
