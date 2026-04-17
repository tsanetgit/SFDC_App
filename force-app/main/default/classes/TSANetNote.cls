/** Represents a TSANet note associated with a collaboration case. */
global inherited sharing class TSANetNote {
    /** TSANet note identifier. */
    @AuraEnabled
    global Integer id { get; set; }
    /** TSANet case identifier this note belongs to. */
    @AuraEnabled
    global Integer caseId { get; set; }
    /** Name of the note creator. */
    @AuraEnabled
    global String creatorName { get; set; }
    /** Email of the note creator. */
    @AuraEnabled
    global String creatorEmail { get; set; }
    /** Note summary text. */
    @AuraEnabled
    global String summary { get; set; }
    /** Detailed note description. */
    @AuraEnabled
    global String description { get; set; }
    /** Note priority level. */
    @AuraEnabled
    global String priority { get; set; }
    /** Current note status. */
    @AuraEnabled
    global String status { get; set; }
    /** Unique token identifying the note. */
    @AuraEnabled
    global String token { get; set; }
    /** Timestamp when the note was created. */
    @AuraEnabled
    global String createdAt { get; set; }
    /** Timestamp when the note was last updated. */
    @AuraEnabled
    global String updatedAt { get; set; }

}