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
    /**
     * Optional note type code (TSANetNote__c.Type__c API name, e.g. public, partner, system, escalation, status).
     * Blank is sent as "type": null so TSANet stores the note without a type.
     */
    @AuraEnabled
    global String type { get; set; }

    /** Information about who submitted the note. */
    @AuraEnabled
    global TSANetSubmittedBy submittedBy { get; set; }

    /** JSON key of the note type; the API expects a NoteTypeReferenceDTO object here. */
    private static final String TYPE_KEY = 'type';
    /** Key of the type code inside NoteTypeReferenceDTO. */
    private static final String TYPE_CODE_KEY = 'code';

    /**
     * Serialises the form as a POST /notes body (CaseNoteTemplateDTO).
     * The flat type code becomes { "code": "<code>" }; a blank type is sent as an explicit null.
     * @return JSON request body
     */
    public String toRequestBody(){
        Map<String, Object> payload = (Map<String, Object>) System.JSON.deserializeUntyped(System.JSON.serialize(this, true));
        payload.put(TYPE_KEY, String.isNotBlank(type) ? new Map<String, Object>{ TYPE_CODE_KEY => type } : null);
        return System.JSON.serialize(payload);
    }

}