public class TSANetFileUploadResult {
    
	public String fileName;
    public String receiverStatus;
    public String receiverMessage;
    public String submitterStatus;
    public String submitterMessage;
    public Boolean completeSuccess;
    public Boolean partialSuccess;
    
    public static List<TSANetFileUploadResult> parse(String json){ 
		return (List<TSANetFileUploadResult>) System.JSON.deserialize(json, List<TSANetFileUploadResult>.class);
    }
}