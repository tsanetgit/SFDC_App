global class TSANetNoteResponse {

    global Integer id;
    global Integer caseId;
    global String creatorUsername;
    global String summary;
    global String description;
    global String priority;
    global String status;
    global String token;
    
    global static List<TSANetNoteResponse> parse(String json) {
        return (List<TSANetNoteResponse>) System.JSON.deserialize(json, List<TSANetNoteResponse>.class);
    }
    
    global static TSANetNoteResponse parseOneRecord(String json) {
        return (TSANetNoteResponse) System.JSON.deserialize(json, TSANetNoteResponse.class);
    }
}