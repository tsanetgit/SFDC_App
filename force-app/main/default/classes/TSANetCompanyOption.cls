/** Represents a selectable company option in the TSANet UI. */
global inherited sharing class TSANetCompanyOption {

    /** Display value for the option. */
    @AuraEnabled
    global String value;
    /** Label displayed to the user. */
    @AuraEnabled
    global String label { get; set; }
    /** Company identifier. */
    @AuraEnabled
    global Integer companyId { get; set; }
    /** Department identifier within the company. */
    @AuraEnabled
    global Integer departmentId { get; set; }

    /**
     * Constructs a company option with the given label, company, and department.
     * @param label display label for the option
     * @param companyId company identifier
     * @param departmentId department identifier
     */
    global TSANetCompanyOption(String label, Integer companyId, Integer departmentId) {
        this.label = label;
        this.companyId = companyId;
        this.departmentId = departmentId;
    }
}
