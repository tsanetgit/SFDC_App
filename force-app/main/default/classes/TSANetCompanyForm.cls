/** Form data submitted when creating a TSANet collaboration case. */
global inherited sharing class TSANetCompanyForm {

    /** Document identifier for the form submission. */
    @AuraEnabled
    global String documentId { get; set; }
    /** Internal case number of the submitter. */
    @AuraEnabled
    global String internalCaseNumber { get; set; }
    /** Optional internal case number on the receiver side. */
    @AuraEnabled
    global String optionalRecieverInternalCaseNumber { get; set; }
    /** Summary of the problem being reported. */
    @AuraEnabled
    global String problemSummary { get; set; }
    /** Detailed description of the problem. */
    @AuraEnabled
    global String problemDescription { get; set; }
    /** Priority level of the case. */
    @AuraEnabled
    global String casePriority { get; set; }
    /** Read-only administrative note. */
    @AuraEnabled
    global String readonlyAdminNote { get; set; }
    /** Read-only escalation instructions. */
    @AuraEnabled
    global String readonlyEscalationInstructions { get; set; }
    /** Whether this is a test submission. */
    @AuraEnabled
    global Boolean testSubmission { get; set; }

    /** Custom field data for the form. */
    @AuraEnabled
    global TSANetCustomerData[] customFields { get; set; } //customerData

}