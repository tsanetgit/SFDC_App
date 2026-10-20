@IsTest

public class TSANetNoteTest {


    @IsTest
    public static void TSANetCompanyFormParseTest(){
        String json = '{ "id": 149, "caseId": 2717, "creatorUsername": null, "creatorEmail": "John.Smith@cisco.com", "creatorName": "John Smith", "summary": "outbound note", "description": "<p>testing note</p>", "priority": "LOW", "status": "ENTERED", "token": "mVLdaPGRpzrKQ7M4r4", "createdAt": "2024-06-19T17:15:26Z", "updatedAt": "2024-09-12T19:31:52Z" }';
        TSANetNote note = (TSANetNote) System.JSON.deserialize(json, TSANetNote.class);
        System.assertEquals(true,
                            note.id == 149 &&
                            note.caseId == 2717 &&
                            note.creatorEmail == 'John.Smith@cisco.com' &&
                            note.creatorName == 'John Smith' &&
                            note.summary == 'outbound note' &&
                            note.description == '<p>testing note</p>' &&
                            note.status == 'ENTERED' &&
                            note.token == 'mVLdaPGRpzrKQ7M4r4' &&
                            note.createdAt == '2024-06-19T17:15:26Z' &&
                            note.updatedAt == '2024-09-12T19:31:52Z'
                           );
    }


    @IsTest
    public static void TSANetNoteFormParseTest(){
        String json = '{ "summary": "subject 1", "description": "description 1", "priority": "low" }';
        TSANetNoteForm note = (TSANetNoteForm) System.JSON.deserialize(json, TSANetNoteForm.class);
        System.assertEquals(true,
                            note.summary == 'subject 1' &&
                            note.description == 'description 1' &&
                            note.priority == 'low'
                           );
    }

    /** The request body must send the type as NoteTypeReferenceDTO ({ "code": ... }). */
    @IsTest
    public static void toRequestBodyWrapsTypeCodeInObject(){
        TSANetNoteForm form = new TSANetNoteForm();
        form.summary = 'subject';
        form.description = 'body';
        form.priority = 'LOW';
        form.type = 'public';

        Map<String, Object> payload = (Map<String, Object>) System.JSON.deserializeUntyped(form.toRequestBody());

        Map<String, Object> type = (Map<String, Object>) payload.get('type');
        System.assertEquals('public', type.get('code'), 'Type must be sent as { code }');
        System.assertEquals('subject', payload.get('summary'));
        System.assertEquals('LOW', payload.get('priority'));
    }

    /** A blank type is sent as an explicit null so TSANet stores the note without a type. */
    @IsTest
    public static void toRequestBodySendsNullForBlankType(){
        TSANetNoteForm form = new TSANetNoteForm();
        form.summary = 'subject';
        form.type = '';

        String body = form.toRequestBody();
        Map<String, Object> payload = (Map<String, Object>) System.JSON.deserializeUntyped(body);

        System.assertEquals(true, payload.containsKey('type'), 'The type key must be present: ' + body);
        System.assertEquals(null, payload.get('type'), 'Blank type must be sent as null');
    }

}