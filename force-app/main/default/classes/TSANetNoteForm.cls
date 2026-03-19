global class TSANetNoteForm {
    
    @AuraEnabled 
    global String summary { get; set; }
    @AuraEnabled 
    global String description { get; set; }
    @AuraEnabled 
    global String priority { get; set; }
    
    @AuraEnabled 
    global TSANetSubmittedBy submittedBy { get; set; }
    
}