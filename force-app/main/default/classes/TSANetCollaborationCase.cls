/** Data transfer object representing a TSANet collaboration case. */
global inherited sharing class TSANetCollaborationCase {
    /** Unique identifier of the collaboration case. */
	@AuraEnabled
    global Integer id { get; set; }
    /** Name of the submitting company. */
    @AuraEnabled
    global String submitCompanyName { get; set; }
    /** Id of the submitting company. */
    @AuraEnabled
    global Integer submitCompanyId { get; set; }
    /** Case number from the submitter side. */
    @AuraEnabled
    global String submitterCaseNumber { get; set; }
    /** Name of the receiving company. */
    @AuraEnabled
    global String receiveCompanyName { get; set; }
    /** Id of the receiving company. */
    @AuraEnabled
    global Integer receiveCompanyId { get; set; }
    /** Case number from the receiver side. */
    @AuraEnabled
    global String receiverCaseNumber { get; set; }
    /** Brief summary of the collaboration case. */
    @AuraEnabled
    global String summary { get; set; }
    /** Detailed description of the collaboration case. */
    @AuraEnabled
    global String description { get; set; }
    /** Priority level of the case. */
    @AuraEnabled
    global String priority { get; set; }
    /** Current status of the case. */
    @AuraEnabled
    global String status { get; set; }
    /** Security token for the case. */
    @AuraEnabled
    global String token  { get; set; }
    /** Timestamp when the case was created. */
    @AuraEnabled
    global String createdAt { get; set; }
    /** Timestamp when the case was last updated. */
    @AuraEnabled
    global String updatedAt { get; set; }
    /** Timestamp when the case was deleted, if applicable. */
    @AuraEnabled
    global String deletedAt { get; set; }
    /** Whether the case has been responded to. */
    @AuraEnabled
    global Boolean responded { get; set; }
    /** Deadline for responding to the case. */
    @AuraEnabled
    global String respondBy { get; set; }
    /** Whether feedback has been requested. */
    @AuraEnabled
    global Boolean feedbackRequested { get; set; }
    /** Whether a reminder has been sent. */
    @AuraEnabled
    global Boolean reminderSent { get; set; }
    /** Note explaining the priority level. */
    @AuraEnabled
    global String priorityNote { get; set; }
    /** Escalation instructions for the case. */
    @AuraEnabled
    global String escalationInstructions { get; set; }
    /** Whether this is a test case. */
    @AuraEnabled
    global Boolean testCase { get; set; }
    /** Custom field values associated with the case. */
    @AuraEnabled
    global CustomFields[] customFields { get; set; }
    /** Notes attached to the case. */
    @AuraEnabled
    global TSANetNote[] caseNotes { get; set; }
    /** User who submitted the case. */
    @AuraEnabled
    global TSANetUser submittedBy { get; set; }
    /** Responses to the collaboration case. */
    @AuraEnabled
    global TSANetCaseRequest[] caseResponses { get; set; }

    /** Wrapper for custom field data on a collaboration case. */
    global class CustomFields {
        /** Unique identifier of the custom field. */
        @AuraEnabled
        global String id { get; set; }
        /** Section the custom field belongs to. */
        @AuraEnabled
        global String section { get; set; }
        /** Display name of the custom field. */
        @AuraEnabled
        global String fieldName { get; set; }
        /** Value of the custom field. */
        @AuraEnabled
        global String value { get; set; }
    }

}