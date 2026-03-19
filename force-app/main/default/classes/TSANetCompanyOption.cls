global class TSANetCompanyOption {
    
	@AuraEnabled 
    global String label { get; set; }
    @AuraEnabled
    global Integer companyId { get; set; }
    @AuraEnabled
    global String value;
    @AuraEnabled
    global Integer departmentId { get; set; }

    global TSANetCompanyOption(String label, Integer companyId, Integer departmentId) {
        this.label = label;
        this.companyId = companyId;
        this.departmentId = departmentId;
    }
}