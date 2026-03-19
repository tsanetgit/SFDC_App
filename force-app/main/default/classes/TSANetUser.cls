global class TSANetUser {
    @AuraEnabled 
    global Integer id { get; set; }
    @AuraEnabled 
    global String username { get; set; }
    @AuraEnabled 
    global String firstName { get; set; }
    @AuraEnabled 
    global String lastName { get; set; }
    @AuraEnabled 
    global String email { get; set; }
    @AuraEnabled 
    global String phone { get; set; }
    @AuraEnabled 
    global String phoneCountryCode { get; set; }
    @AuraEnabled 
    global String description { get; set; }
    @AuraEnabled 
    global String city { get; set; }
}