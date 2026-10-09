@IsTest

public class TSANetNoteResponseTest {


    @IsTest
    public static void parseTest(){

        String json = '[{ "id": 151, "caseId": 2718, "creatorUsername": null, "creatorEmail": "John.Smith@cisco.com", "summary": "new note", "description": "<p>testing</p>", "priority": "low", "status": "entered", "token": "HeRU7whkYdvVXS9Y8p", "createdAt": "2024-06-19T17:20:23Z", "updatedAt": "2024-06-19T17:20:24Z" }]';
        String oneRecord = '{ "id": 151, "caseId": 2718, "creatorUsername": null, "creatorEmail": "John.Smith@cisco.com", "summary": "new note", "description": "<p>testing</p>", "priority": "low", "status": "entered", "token": "HeRU7whkYdvVXS9Y8p", "createdAt": "2024-06-19T17:20:23Z", "updatedAt": "2024-06-19T17:20:24Z" }';
        TSANetNoteResponse[] notes = TSANetNoteResponse.parse(json);
        TSANetNoteResponse note = TSANetNoteResponse.parseOneRecord(oneRecord);

        System.assertNotEquals(null, notes, 'Parsing a note list should not return null');
        System.assertEquals(false, notes.isEmpty(), 'Expected at least one parsed note');
        System.assertEquals('HeRU7whkYdvVXS9Y8p', note.token, 'Expected the token from the single-record payload');
        System.assertEquals('new note', note.summary, 'Expected the summary from the single-record payload');
    }
}