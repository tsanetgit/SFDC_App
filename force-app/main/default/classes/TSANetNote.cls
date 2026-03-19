global class TSANetNote {
    @AuraEnabled 
    global Integer id { get; set; }
    @AuraEnabled 
    global Integer caseId { get; set; }
    @AuraEnabled 
    global String creatorName { get; set; }
    @AuraEnabled 
    global String creatorEmail { get; set; }
    @AuraEnabled 
    global String summary { get; set; }
    @AuraEnabled 
    global String description { get; set; }
    @AuraEnabled 
    global String priority { get; set; }
    @AuraEnabled 
    global String status { get; set; }
    @AuraEnabled 
    global String token { get; set; }
    @AuraEnabled 
    global String createdAt { get; set; }
    @AuraEnabled 
    global String updatedAt { get; set; }

}