global class TSANetApprovalForm {
	@AuraEnabled 
    global String caseNumber { get; set; }
    @AuraEnabled 
    global String engineerName { get; set; }
    @AuraEnabled 
    global String engineerEmail { get; set; }
    @AuraEnabled 
    global String engineerPhone { get; set; }
    @AuraEnabled 
    global String nextSteps { get; set; }
}