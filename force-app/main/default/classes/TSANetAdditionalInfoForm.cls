global class TSANetAdditionalInfoForm {
    @AuraEnabled 
    @SerializedName('Requested Information')
    global String requestedInformation { get; set; }
}