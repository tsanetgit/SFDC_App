/** Container for TSANet case, response, and note records used in batch operations. */
public inherited sharing class TSANetData {
    /** TSANet case records. */
    public tsanetconnect__TSANetCase__c[] cases;
    /** TSANet response records. */
    public tsanetconnect__TSANetResponse__c[] responses;
    /** TSANet note records. */
    public tsanetconnect__TSANetNote__c[] notes;

    /** Initializes an empty TSANetData container. */
    public TSANetData(){
        // Default constructor
    }
}
