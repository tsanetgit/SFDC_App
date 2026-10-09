@IsTest
public class ErrorLoggerTest {

    // Helper: relations map (can be null values, the logger handles that)
    private static Map<String, String> buildRelations(Id caseId, Id tsaNetCaseId, Id tsaNetNoteId) {
        return new Map<String, String>{
            'caseId' => (caseId == null ? null : String.valueOf(caseId)),
            'tsaNetCaseId' => (tsaNetCaseId == null ? null : String.valueOf(tsaNetCaseId)),
            'tsaNetNoteId' => (tsaNetNoteId == null ? null : String.valueOf(tsaNetNoteId))
        };
    }

    @IsTest
    static void test_logError_exception_withContext_insertsRow() {
        Test.startTest();
        ErrorLogger.logError(new AuraHandledException('boom'), 'UT_logError_1');
        Test.stopTest();

        // Verify a row was inserted (if FLS blocks, method swallows exception and this may fail in that org)
        List<tsanetconnect__TSANetError__c> rows = [
            SELECT Id, tsanetconnect__Context__c, tsanetconnect__ErrorMessage__c, tsanetconnect__Type__c
            FROM tsanetconnect__TSANetError__c
            WHERE tsanetconnect__Context__c = 'UT_logError_1'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals(1, rows.size(), 'Expected an error log record to be created');
        System.assert(rows[0].tsanetconnect__ErrorMessage__c != null, 'Message should be set');
        System.assert(rows[0].tsanetconnect__Type__c != null, 'Type should be set');
    }

    @IsTest
    static void test_logError_exception_withRelations_insertsRow() {
        // Optional related Case (safe to use; logger accepts nulls too)
        Case c = new Case(Subject = 'UT case', Status = 'New', Origin = 'Phone');
        insert c;

        Map<String, String> relations = buildRelations(c.Id, null, null);

        Test.startTest();
        ErrorLogger.logError(new AuraHandledException('npe'), 'UT_logError_2', relations);
        Test.stopTest();

        List<tsanetconnect__TSANetError__c> rows = [
            SELECT Id, Name, tsanetconnect__Context__c, tsanetconnect__Case__c
            FROM tsanetconnect__TSANetError__c
            WHERE tsanetconnect__Context__c = 'UT_logError_2'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals(1, rows.size(), 'Expected an error log record to be created');
        System.assertEquals(c.Id, rows[0].tsanetconnect__Case__c, 'Case lookup should be set when provided');
        System.assert(rows[0].Name != null, 'Name should be set (context + timestamp)');
        tsanetconnect__TSANetError__c withMessage = [
            SELECT tsanetconnect__ErrorMessage__c
            FROM tsanetconnect__TSANetError__c
            WHERE Id = :rows[0].Id
        ];
        System.assertEquals(true, withMessage.tsanetconnect__ErrorMessage__c.contains('caseId=' + c.Id),
            'Error message should include the related Case Id');
    }

    @IsTest
    static void test_stackTrace_truncated_to_field_length() {
        List<String> parts = new List<String>();
        for (Integer i = 0; i < 400; i++) {
            parts.add('x');
        }
        String longStack = String.join(parts, '');

        Map<String, Object> ex = new Map<String, Object>{
            'message' => 'long trace',
            'type' => 'UT',
            'stackTrace' => longStack
        };

        Test.startTest();
        ErrorLogger.logUIError(ex, 'UT_longStack', new Map<String, String>());
        Test.stopTest();

        tsanetconnect__TSANetError__c row = [
            SELECT tsanetconnect__StackTrace__c
            FROM tsanetconnect__TSANetError__c
            WHERE tsanetconnect__Context__c = 'UT_longStack'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals(255, row.tsanetconnect__StackTrace__c.length(), 'Stack trace must fit Text(255)');
    }

    @IsTest
    static void test_logUIError_insertsRow() {
        Case c = new Case(Subject = 'UT case ui', Status = 'New', Origin = 'Phone');
        insert c;

        Map<String, Object> ex = new Map<String, Object>{
            'message' => 'ui boom',
            'type' => 'UI_ERROR',
            'stackTrace' => 'stack...'
        };

        Map<String, String> relations = buildRelations(c.Id, null, null);

        Test.startTest();
        ErrorLogger.logUIError(ex, 'UT_logUIError_1', relations);
        Test.stopTest();

        List<tsanetconnect__TSANetError__c> rows = [
            SELECT Id, tsanetconnect__Context__c, tsanetconnect__ErrorMessage__c, tsanetconnect__Type__c, tsanetconnect__StackTrace__c
            FROM tsanetconnect__TSANetError__c
            WHERE tsanetconnect__Context__c = 'UT_logUIError_1'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals(1, rows.size(), 'Expected a UI error log record to be created');
        System.assertEquals('ui boom', rows[0].tsanetconnect__ErrorMessage__c);
        System.assertEquals('UI_ERROR', rows[0].tsanetconnect__Type__c);
        System.assertEquals('stack...', rows[0].tsanetconnect__StackTrace__c);
    }

    @IsTest
    static void test_logError_messageOnly_insertsRow() {
        Test.startTest();
        ErrorLogger.logError('plain message', 'UT_logError_msg');
        Test.stopTest();

        Integer cnt = [SELECT COUNT() FROM tsanetconnect__TSANetError__c];
        System.assertEquals(1, cnt, 'Expected a message-only error log record to be created');
    }

    @IsTest
    static void test_getLogError_buildsSObject() {
        tsanetconnect__TSANetError__c rec = ErrorLogger.getLogError('m', 'ctx');
        System.assertEquals('m', rec.tsanetconnect__ErrorMessage__c);
        System.assertEquals('ctx', rec.tsanetconnect__Context__c);
        System.assertEquals(null, rec.Id, 'Should not be inserted by getLogError');
    }

    @IsTest
    static void test_logErrors_bulkInsert() {
        tsanetconnect__TSANetError__c e1 = new tsanetconnect__TSANetError__c(
            Name = 'UT bulk 1',
            tsanetconnect__Context__c = 'UT_bulk',
            tsanetconnect__ErrorMessage__c = 'm1'
        );
        tsanetconnect__TSANetError__c e2 = new tsanetconnect__TSANetError__c(
            Name = 'UT bulk 2',
            tsanetconnect__Context__c = 'UT_bulk',
            tsanetconnect__ErrorMessage__c = 'm2'
        );

        Test.startTest();
        ErrorLogger.logErrors(new tsanetconnect__TSANetError__c[] { e1, e2 });
        Test.stopTest();

        Integer cnt = [
            SELECT COUNT()
            FROM tsanetconnect__TSANetError__c
            WHERE tsanetconnect__Context__c = 'UT_bulk'
        ];
        System.assertEquals(2, cnt, 'Expected 2 bulk error log records to be created');
    }
}