@isTest
public class TSANetNoteTest {
    
    @isTest
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
    
    @isTest
    public static void TSANetNoteFormParseTest(){
        String json = '{ "summary": "subject 1", "description": "description 1", "priority": "low" }';
        TSANetNoteForm note = (TSANetNoteForm) System.JSON.deserialize(json, TSANetNoteForm.class);
        System.assertEquals(true, 
                            note.summary == 'subject 1' && 
                            note.description == 'description 1' && 
                            note.priority == 'low' 
                           );
    }

}