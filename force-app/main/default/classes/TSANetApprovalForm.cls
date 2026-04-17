/** Form data for approving a TSANet collaboration request. */
global inherited sharing class TSANetApprovalForm {
    /** Case number associated with the approval. */
	@AuraEnabled
    global String caseNumber { get; set; }
    /** Name of the assigned engineer. */
    @AuraEnabled
    global String engineerName { get; set; }
    /** Email of the assigned engineer. */
    @AuraEnabled
    global String engineerEmail { get; set; }
    /** Phone number of the assigned engineer. */
    @AuraEnabled
    global String engineerPhone { get; set; }
    /** Next steps or notes for the collaboration. */
    @AuraEnabled
    global String nextSteps { get; set; }
}