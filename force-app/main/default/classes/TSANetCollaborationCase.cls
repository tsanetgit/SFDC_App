global class TSANetCollaborationCase {
	@AuraEnabled 
    global Integer id { get; set; }
    @AuraEnabled 
    global String submitCompanyName { get; set; }
    @AuraEnabled 
    global Integer submitCompanyId { get; set; }
    @AuraEnabled 
    global String submitterCaseNumber { get; set; }
    @AuraEnabled 
    global String receiveCompanyName { get; set; }
    @AuraEnabled 
    global Integer receiveCompanyId { get; set; }
    @AuraEnabled 
    global String receiverCaseNumber { get; set; }
    @AuraEnabled 
    global String summary { get; set; }
    @AuraEnabled 
    global String description { get; set; }
    @AuraEnabled 
    global String priority { get; set; }
    @AuraEnabled 
    global String status { get; set; }
    @AuraEnabled 
    global String token  { get; set; }
    @AuraEnabled 
    global String createdAt { get; set; }
    @AuraEnabled 
    global String updatedAt { get; set; }
    @AuraEnabled 
    global String deletedAt { get; set; }
    @AuraEnabled 
    global Boolean responded { get; set; }
    @AuraEnabled 
    global String respondBy { get; set; }
    @AuraEnabled 
    global Boolean feedbackRequested { get; set; }
    @AuraEnabled 
    global Boolean reminderSent { get; set; }
    @AuraEnabled 
    global String priorityNote { get; set; }
    @AuraEnabled 
    global String escalationInstructions { get; set; }
    @AuraEnabled 
    global Boolean testCase { get; set; }
    @AuraEnabled 
    global CustomFields[] customFields { get; set; }
    @AuraEnabled
    global TSANetNote[] caseNotes { get; set; }
    @AuraEnabled
    global TSANetUser submittedBy { get; set; }
    @AuraEnabled
    global TSANetCaseRequest[] caseResponses { get; set; }
    
    global class CustomFields {
        @AuraEnabled 
        global String id { get; set; }
        @AuraEnabled 
        global String section { get; set; }
        @AuraEnabled 
        global String fieldName { get; set; }
        @AuraEnabled 
        global String value { get; set; }
    }
        
}