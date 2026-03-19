global class TSANetRequestInfoForm {
    @AuraEnabled 
    global String engineerName { get; set; }
    @AuraEnabled 
    global String engineerEmail { get; set; }
    @AuraEnabled 
    global String engineerPhone { get; set; }
    @AuraEnabled
    global String requestedInformation { get; set; }
}