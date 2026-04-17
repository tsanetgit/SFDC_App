/** DTO representing a TSANet user profile. */
global inherited sharing class TSANetUser {
    /** TSANet user identifier. */
    @AuraEnabled
    global Integer id { get; set; }
    /** TSANet username. */
    @AuraEnabled
    global String username { get; set; }
    /** First name of the user. */
    @AuraEnabled
    global String firstName { get; set; }
    /** Last name of the user. */
    @AuraEnabled
    global String lastName { get; set; }
    /** Email address of the user. */
    @AuraEnabled
    global String email { get; set; }
    /** Phone number of the user. */
    @AuraEnabled
    global String phone { get; set; }
    /** ISO country code for the user's phone number. */
    @AuraEnabled
    global String phoneCountryCode { get; set; }
    /** Free-text description of the user. */
    @AuraEnabled
    global String description { get; set; }
    /** City where the user is located. */
    @AuraEnabled
    global String city { get; set; }
}