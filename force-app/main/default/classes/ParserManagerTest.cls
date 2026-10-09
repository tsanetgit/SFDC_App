/** Unit tests for ParserManager null-safe mapping of optional API fields. */
@IsTest
public class ParserManagerTest {

    @IsTest
    static void testParseSubmittedByNullDoesNotLogAnError() {
        String json = '[{ "id": 2718, "token": "no-submitter-token", "summary": "No submitter",'
            + ' "priority": "LOW", "status": "ACCEPTED", "responded": true,'
            + ' "feedbackRequested": false, "reminderSent": false,'
            + ' "createdAt": "2024-06-19T17:17:00Z", "customFields": [],'
            + ' "caseNotes": [], "caseResponses": [] }]';

        Test.startTest();
            TSANetData data = ParserManager.parseTSANetCases(json, null);
        Test.stopTest();

        System.assertEquals(1, data.cases.size(), 'The case should still parse without submittedBy');
        System.assertEquals('no-submitter-token', data.cases[0].tsanetconnect__Token__c);
        System.assertEquals(0, [
            SELECT COUNT() FROM tsanetconnect__TSANetError__c
            WHERE tsanetconnect__Context__c = 'SUBMITTED_BY_MAPPING_ERROR'
        ], 'A missing submittedBy object is valid API data and must not be logged');
    }

    @IsTest
    static void testMappingErrorIncludesTokenAndExternalId() {
        // Force a real mapping failure: submittedBy is present but not an object.
        Map<String, Object> fieldMap = new Map<String, Object>{
            'id' => 2718,
            'token' => 'broken-token',
            'submittedBy' => 'not-an-object'
        };

        Test.startTest();
            ParserManager.parseSubmittedBy(new tsanetconnect__TSANetCase__c(), fieldMap, null);
        Test.stopTest();

        tsanetconnect__TSANetError__c[] errors = [
            SELECT tsanetconnect__ErrorMessage__c, tsanetconnect__Context__c
            FROM tsanetconnect__TSANetError__c
            WHERE tsanetconnect__Context__c = 'SUBMITTED_BY_MAPPING_ERROR'
        ];
        System.assertEquals(1, errors.size(), 'Unexpected types on submittedBy should still be logged');
        System.assertEquals(true, errors[0].tsanetconnect__ErrorMessage__c.contains('token=broken-token'),
            'The log should name the collaboration request token: ' + errors[0].tsanetconnect__ErrorMessage__c);
        System.assertEquals(true, errors[0].tsanetconnect__ErrorMessage__c.contains('tsaNetExternalId=2718'),
            'The log should name the TSANet case id: ' + errors[0].tsanetconnect__ErrorMessage__c);
    }

    /** Verifies note type, direction and companyId are mapped during collaboration sync. */
    @IsTest
    static void testParseCaseNotesMapsTypeDirectionAndCompanyId() {
        String json = '[{ "id": 2718, "token": "case-token", "summary": "Case", "customFields": [], "caseResponses": [],'
            + ' "caseNotes": ['
            + '   { "id": 1, "caseId": 2718, "companyId": 1100, "companyName": "Demo", "summary": "Public",'
            + '     "priority": "LOW", "type": "USER_PUBLIC", "direction": "OUTBOUND", "status": "ENTERED", "token": "note-1" },'
            + '   { "id": 2, "caseId": 2718, "creatorName": "SYSTEM", "summary": "System",'
            + '     "priority": "LOW", "type": "SYSTEM", "status": "ENTERED", "token": "note-2" }'
            + ' ] }]';

        Test.startTest();
            TSANetData data = ParserManager.parseTSANetCases(json, null);
        Test.stopTest();

        System.assertEquals(2, data.notes.size(), 'Both notes should be parsed');
        System.assertEquals('USER_PUBLIC', data.notes[0].tsanetconnect__Type__c);
        System.assertEquals('OUTBOUND', data.notes[0].tsanetconnect__Direction__c);
        System.assertEquals('1100', data.notes[0].tsanetconnect__CompanyId__c);
        System.assertEquals('SYSTEM', data.notes[1].tsanetconnect__Type__c);
        System.assertEquals(null, data.notes[1].tsanetconnect__Direction__c, 'Platform notes have no direction');
        System.assertEquals(null, data.notes[1].tsanetconnect__CompanyId__c, 'Platform notes have no company');
    }

    /** Verifies the created-note API response maps the new note fields. */
    @IsTest
    static void testParseSingleNoteMapsTypeDirectionAndCompanyId() {
        String json = '{ "id": 5, "caseId": 2718, "companyId": 1099, "summary": "Partner note", "priority": "LOW",'
            + ' "type": "USER_PARTNER", "direction": "OUTBOUND", "status": "ENTERED", "token": "note-5" }';

        Test.startTest();
            tsanetconnect__TSANetNote__c note = ParserManager.parseTSANetNote(json);
        Test.stopTest();

        System.assertEquals('USER_PARTNER', note.tsanetconnect__Type__c);
        System.assertEquals('OUTBOUND', note.tsanetconnect__Direction__c);
        System.assertEquals('1099', note.tsanetconnect__CompanyId__c);
    }
}
