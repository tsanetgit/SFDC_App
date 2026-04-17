/** Wrapper for paginated TSANet case data returned by the API. */
public inherited sharing class TSANetCaseDataResponse {

    /** List of TSANet case records in this page. */
    public List<TSANetCaseRecord> content;
    //public Integer currentNumber;
    /** Number of records in this page. */
    public Integer size;
    /** Total number of records across all pages. */
    public Integer totalElements;
    /** Total number of pages available. */
    public Integer totalPages;

    /**
     * Deserializes JSON into a TSANetCaseDataResponse instance.
     * @param json the JSON string to parse
     * @return the deserialized response
     */
    public static TSANetCaseDataResponse parse(String json){
        //json = json.replaceAll('"number"', '"currentNumber"');
        return (TSANetCaseDataResponse) System.JSON.deserialize(json, TSANetCaseDataResponse.class);
    }

}