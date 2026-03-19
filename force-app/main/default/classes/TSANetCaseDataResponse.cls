public class TSANetCaseDataResponse {
    
    public List<TSANetCaseRecord> content;
    //public Integer currentNumber;
    public Integer size;
    public Integer totalElements;
    public Integer totalPages;
    
    public static TSANetCaseDataResponse parse(String json){
        //json = json.replaceAll('"number"', '"currentNumber"');
        return (TSANetCaseDataResponse) System.JSON.deserialize(json, TSANetCaseDataResponse.class);
    }
    
}