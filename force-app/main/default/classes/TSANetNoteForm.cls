/** Form data for creating or updating a TSANet note. */
global inherited sharing class TSANetNoteForm {

    /** Note summary text. */
    @AuraEnabled
    global String summary { get; set; }
    /** Detailed note description. */
    @AuraEnabled
    global String description { get; set; }
    /** Note priority level. */
    @AuraEnabled
    global String priority { get; set; }
    /** Optional note type (USER_PUBLIC or USER_PARTNER); omitted means USER_PARTNER on TSANet side. */
    @AuraEnabled
    global String type { get; set; }

    /** Information about who submitted the note. */
    @AuraEnabled
    global TSANetSubmittedBy submittedBy { get; set; }

}