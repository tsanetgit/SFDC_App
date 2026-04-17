/** Form data for requesting additional information on a TSANet case. */
global inherited sharing class TSANetRequestInfoForm {
    /** Name of the requesting engineer. */
    @AuraEnabled
    global String engineerName { get; set; }
    /** Email of the requesting engineer. */
    @AuraEnabled
    global String engineerEmail { get; set; }
    /** Phone number of the requesting engineer. */
    @AuraEnabled
    global String engineerPhone { get; set; }
    /** Description of the information being requested. */
    @AuraEnabled
    global String requestedInformation { get; set; }
}