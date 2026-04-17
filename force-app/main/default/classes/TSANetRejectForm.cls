/** Form data for rejecting a TSANet collaboration case. */
global inherited sharing class TSANetRejectForm {
    /** Name of the rejecting engineer. */
	@AuraEnabled
    global String engineerName { get; set; }
    /** Email of the rejecting engineer. */
    @AuraEnabled
    global String engineerEmail { get; set; }
    /** Phone number of the rejecting engineer. */
    @AuraEnabled
    global String engineerPhone { get; set; }
    /** Reason for rejecting the case. */
    @AuraEnabled
    global String reason { get; set; }
}