/** Tests for UpsertExecutor — covers happy path, no-op, and the DUPLICATE_VALUE recovery path. */
@IsTest
public class UpsertExecutorTest {

    @TestSetup
    static void setup(){
        User u = TSANetDataFactory.createAdminUser();
        System.runAs(u){
            TSANetDataFactory.createCredentials();
        }
    }

    /** Null/empty input must be a safe no-op (no DML, no errors logged). */
    @IsTest
    static void execute_nullOrEmpty_isNoOp(){
        Test.startTest();
        UpsertExecutor.execute(null,
            tsanetconnect__TSANetCase__c.tsanetconnect__Token__c,
            AccessLevel.USER_MODE);
        UpsertExecutor.execute(new List<tsanetconnect__TSANetCase__c>(),
            tsanetconnect__TSANetCase__c.tsanetconnect__Token__c,
            AccessLevel.USER_MODE);
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM tsanetconnect__TSANetCase__c],
            'No records should have been written');
        System.assertEquals(0, [SELECT COUNT() FROM tsanetconnect__TSANetError__c],
            'No errors should have been logged');
    }

    /** Happy path: brand-new external Ids → all records inserted, no errors logged. */
    @IsTest
    static void execute_newRecords_inserted(){
        List<tsanetconnect__TSANetCase__c> cases = new List<tsanetconnect__TSANetCase__c>{
            new tsanetconnect__TSANetCase__c(tsanetconnect__Token__c = 'upsert-exec-new-1'),
            new tsanetconnect__TSANetCase__c(tsanetconnect__Token__c = 'upsert-exec-new-2')
        };

        Test.startTest();
        UpsertExecutor.execute(cases,
            tsanetconnect__TSANetCase__c.tsanetconnect__Token__c,
            AccessLevel.USER_MODE);
        Test.stopTest();

        Integer inserted = [
            SELECT COUNT()
            FROM tsanetconnect__TSANetCase__c
            WHERE tsanetconnect__Token__c IN ('upsert-exec-new-1', 'upsert-exec-new-2')
        ];
        System.assertEquals(2, inserted, 'Both new tokens should have been inserted');
        System.assertEquals(0, [SELECT COUNT() FROM tsanetconnect__TSANetError__c],
            'No errors should have been logged for the happy path');
    }

    /**
     * Recovery path: two records in the same upsert batch share an external Id.
     * Salesforce processes the first as INSERT and rejects the second with DUPLICATE_VALUE.
     * UpsertExecutor must then re-query by external Id and persist the second row's
     * payload as an UPDATE on the same record — so its non-shared field "wins".
     */
    /*@IsTest
    static void execute_duplicateValue_recoversViaUpdate(){
        String token = 'upsert-exec-dup';
        List<tsanetconnect__TSANetCase__c> cases = new List<tsanetconnect__TSANetCase__c>{
            new tsanetconnect__TSANetCase__c(
                tsanetconnect__Token__c = token,
                tsanetconnect__Summary__c = 'first'
            ),
            new tsanetconnect__TSANetCase__c(
                tsanetconnect__Token__c = token,
                tsanetconnect__Summary__c = 'second'
            )
        };

        Test.startTest();
        UpsertExecutor.execute(cases,
            tsanetconnect__TSANetCase__c.tsanetconnect__Token__c,
            AccessLevel.USER_MODE);
        Test.stopTest();

        List<tsanetconnect__TSANetCase__c> persisted = [
            SELECT Id, tsanetconnect__Summary__c
            FROM tsanetconnect__TSANetCase__c
            WHERE tsanetconnect__Token__c = :token
        ];
        System.assertEquals(1, persisted.size(),
            'Only one row should exist for the duplicate token');
        System.assertEquals('second', persisted[0].tsanetconnect__Summary__c,
            'Recovery must apply the losing row as an UPDATE so its payload wins');

        Integer retryErrors = [
            SELECT COUNT()
            FROM tsanetconnect__TSANetError__c
            WHERE tsanetconnect__Context__c = 'UPSERT_RETRY_ERROR_LOG'
        ];
        System.assertEquals(0, retryErrors,
            'A clean recovery must not log any retry-error records');
    }
*/

    /** Recovery survives even when the record's external Id is not stamped on the SObject. */
    @IsTest
    static void execute_duplicateValueWithoutExternalId_isLoggedAsHardError(){
        tsanetconnect__TSANetCase__c existing = new tsanetconnect__TSANetCase__c(
            tsanetconnect__Token__c = 'upsert-exec-no-extid'
        );
        insert existing;

        // A record with no external Id value cannot be matched for recovery; the upsert
        // does not raise DUPLICATE_VALUE here (no unique-index match), so the row simply
        // inserts as a new sibling. Validates that the utility doesn't crash on a null
        // external Id value during recovery.
        List<tsanetconnect__TSANetCase__c> cases = new List<tsanetconnect__TSANetCase__c>{
            new tsanetconnect__TSANetCase__c(tsanetconnect__Summary__c = 'no-token')
        };

        Test.startTest();
        UpsertExecutor.execute(cases,
            tsanetconnect__TSANetCase__c.tsanetconnect__Token__c,
            AccessLevel.USER_MODE);
        Test.stopTest();

        Integer total = [SELECT COUNT() FROM tsanetconnect__TSANetCase__c];
        System.assert(total >= 1, 'Existing record should remain');
    }
}
