/** Represents a custom field entry in a TSANet form submission. */
global inherited sharing class TSANetCustomerData {
    /** Identifier of the custom field. */
    @AuraEnabled
    global String fieldId { get; set; }
    /** Section the field belongs to. */
    @AuraEnabled
    global String section { get; set; }
    /** Display label of the field. */
    @AuraEnabled
    global String label { get; set; }
    /** Value entered for the field. */
    @AuraEnabled
    global String value { get; set; }
}