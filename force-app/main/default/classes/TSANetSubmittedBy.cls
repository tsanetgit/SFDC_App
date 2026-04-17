/** DTO representing the submitter of a TSANet collaboration case. */
global inherited sharing class TSANetSubmittedBy {
    /** First name of the submitter. */
    @AuraEnabled
    global String firstName { get; set; }
    /** Last name of the submitter. */
    @AuraEnabled
    global String lastName { get; set; }
}