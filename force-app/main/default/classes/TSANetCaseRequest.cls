/** Represents a request payload for a TSANet case response submission. */
public inherited sharing class TSANetCaseRequest {

    /** TSANet response identifier. */
    public Integer id;
    /** Type of the response. */
    public String type;
    /** Timestamp when the response was created. */
    public String createdAt;
    /** Case number from the responding company. */
    public String caseNumber { get; set; }
    /** Name of the assigned engineer. */
    public String engineerName { get; set; }
    /** Email of the assigned engineer. */
    public String engineerEmail { get; set; }
    /** Phone of the assigned engineer. */
    public String engineerPhone { get; set; }
    /** Next steps or notes for the case. */
    public String nextSteps { get; set; }
}
