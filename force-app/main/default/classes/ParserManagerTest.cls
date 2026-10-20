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

    /** Verifies note type code, direction and companyId are mapped during collaboration sync. */
    @IsTest
    static void testParseCaseNotesMapsTypeDirectionAndCompanyId() {
        String json = '[{ "id": 2718, "token": "case-token", "summary": "Case", "customFields": [], "caseResponses": [],'
            + ' "caseNotes": ['
            + '   { "id": 1, "caseId": 2718, "companyId": 1100, "companyName": "Demo", "summary": "Public",'
            + '     "priority": "LOW", "type": { "code": "public", "displayName": "Public" },'
            + '     "direction": "OUTBOUND", "status": "ENTERED", "token": "note-1" },'
            + '   { "id": 2, "caseId": 2718, "creatorName": "SYSTEM", "summary": "System",'
            + '     "priority": "LOW", "type": { "code": "system", "displayName": "System" }, "status": "ENTERED", "token": "note-2" },'
            + '   { "id": 3, "caseId": 2718, "summary": "Untyped", "priority": "LOW", "type": null, "status": "ENTERED", "token": "note-3" }'
            + ' ] }]';

        Test.startTest();
            TSANetData data = ParserManager.parseTSANetCases(json, null);
        Test.stopTest();

        System.assertEquals(3, data.notes.size(), 'All notes should be parsed');
        System.assertEquals('public', data.notes[0].tsanetconnect__Type__c, 'Type__c must hold the stable type code');
        System.assertEquals('OUTBOUND', data.notes[0].tsanetconnect__Direction__c);
        System.assertEquals('1100', data.notes[0].tsanetconnect__CompanyId__c);
        System.assertEquals('system', data.notes[1].tsanetconnect__Type__c);
        System.assertEquals(null, data.notes[1].tsanetconnect__Direction__c, 'Platform notes have no direction');
        System.assertEquals(null, data.notes[1].tsanetconnect__CompanyId__c, 'Platform notes have no company');
        System.assertEquals(null, data.notes[2].tsanetconnect__Type__c, 'A null type must stay empty, not be treated as public');
    }

    /** Verifies the created-note API response maps the type code and the new note fields. */
    @IsTest
    static void testParseSingleNoteMapsTypeDirectionAndCompanyId() {
        String json = '{ "id": 5, "caseId": 2718, "companyId": 1099, "summary": "Partner note", "priority": "LOW",'
            + ' "type": { "code": "partner", "displayName": "Partner" }, "direction": "OUTBOUND", "status": "ENTERED", "token": "note-5" }';

        Test.startTest();
            tsanetconnect__TSANetNote__c note = ParserManager.parseTSANetNote(json);
        Test.stopTest();

        System.assertEquals('partner', note.tsanetconnect__Type__c);
        System.assertEquals('OUTBOUND', note.tsanetconnect__Direction__c);
        System.assertEquals('1099', note.tsanetconnect__CompanyId__c);
    }

    /** Verifies the type code extractor supports the object shape, the legacy string, and null. */
    @IsTest
    static void testGetNoteTypeCodeHandlesObjectStringAndNull() {
        System.assertEquals('escalation', ParserManager.getNoteTypeCode(new Map<String, Object>{ 'code' => 'escalation', 'displayName' => 'Escalation' }));
        System.assertEquals('status', ParserManager.getNoteTypeCode('status'), 'Legacy plain-string type must still map');
        System.assertEquals(null, ParserManager.getNoteTypeCode(new Map<String, Object>{ 'code' => null }));
        System.assertEquals(null, ParserManager.getNoteTypeCode(null));
    }
}
