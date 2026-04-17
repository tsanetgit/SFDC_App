/** Represents the result of a file upload to TSANet for both submitter and receiver. */
public inherited sharing class TSANetFileUploadResult {

    /** Name of the uploaded file. */
	public String fileName;
    /** Upload status on the receiver side. */
    public String receiverStatus;
    /** Message from the receiver side upload. */
    public String receiverMessage;
    /** Upload status on the submitter side. */
    public String submitterStatus;
    /** Message from the submitter side upload. */
    public String submitterMessage;
    /** Whether the upload succeeded on both sides. */
    public Boolean completeSuccess;
    /** Whether the upload succeeded on at least one side. */
    public Boolean partialSuccess;

    /**
     * Deserializes a JSON string into a list of file upload results.
     * @param json the JSON string to parse
     * @return list of TSANetFileUploadResult instances
     */
    public static List<TSANetFileUploadResult> parse(String json){
		return (List<TSANetFileUploadResult>) System.JSON.deserialize(json, List<TSANetFileUploadResult>.class);
    }
}