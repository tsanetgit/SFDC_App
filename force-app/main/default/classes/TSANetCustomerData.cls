global class TSANetCustomerData {
    @AuraEnabled 
    global String fieldId { get; set; }
    @AuraEnabled 
    global String section { get; set; }
    @AuraEnabled 
    global String label { get; set; }
    @AuraEnabled 
    global String value { get; set; }
}