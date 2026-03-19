global class TSANetCompanyForm {
    
    @AuraEnabled 
    global String documentId { get; set; }
    @AuraEnabled 
    global String internalCaseNumber { get; set; }
    @AuraEnabled 
    global String optionalRecieverInternalCaseNumber { get; set; }
    @AuraEnabled 
    global String problemSummary { get; set; }
    @AuraEnabled 
    global String problemDescription { get; set; }
    @AuraEnabled 
    global String casePriority { get; set; }
    @AuraEnabled 
    global String readonlyAdminNote { get; set; }    
    @AuraEnabled 
    global String readonlyEscalationInstructions { get; set; }
    @AuraEnabled 
    global Boolean testSubmission { get; set; }
    
    @AuraEnabled 
    global TSANetCustomerData[] customFields { get; set; } //customerData
   
}