/** Deserialized TSANet note response from the API. */
global inherited sharing class TSANetNoteResponse {

    /** TSANet note identifier. */
    global Integer id;
    /** TSANet case identifier. */
    global Integer caseId;
    /** Username of the note creator. */
    global String creatorUsername;
    /** Note summary text. */
    global String summary;
    /** Detailed note description. */
    global String description;
    /** Note priority level. */
    global String priority;
    /** Current note status. */
    global String status;
    /** Unique token identifying the note. */
    global String token;

    /**
     * Deserializes a JSON string into a list of TSANetNoteResponse objects.
     * @param json JSON string to parse
     * @return list of deserialized note responses
     */
    global static List<TSANetNoteResponse> parse(String json) {
        return (List<TSANetNoteResponse>) System.JSON.deserialize(json, List<TSANetNoteResponse>.class);
    }

    /**
     * Deserializes a JSON string into a single TSANetNoteResponse object.
     * @param json JSON string to parse
     * @return deserialized note response
     */
    global static TSANetNoteResponse parseOneRecord(String json) {
        return (TSANetNoteResponse) System.JSON.deserialize(json, TSANetNoteResponse.class);
    }
}