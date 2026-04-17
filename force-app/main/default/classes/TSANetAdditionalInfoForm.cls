/** Form data for requesting additional information on a TSANet case. */
global inherited sharing class TSANetAdditionalInfoForm {
    /** The additional information requested. */
    @AuraEnabled
    global String requestedInformation { get; set; }
}