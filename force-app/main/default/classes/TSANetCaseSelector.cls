/** Centralized SOQL for tsanetconnect__TSANetCase__c. */
public with sharing class TSANetCaseSelector {

    /**
     * Full detail with responses subquery, filtered by parent Case Id.
     * @param caseId the parent Case record Id
     * @return list of TSANetCase records with responses
     */
    public static tsanetconnect__TSANetCase__c[] getDetailWithResponsesByCaseId(Id caseId) {
        return [
            SELECT Id, Name, tsanetconnect__Name__c, tsanetconnect__customFields__c,
                   tsanetconnect__EscalationInstructions__c, tsanetconnect__TSANetContact__c,
                   tsanetconnect__FirstName__c, tsanetconnect__LastName__c, tsanetconnect__Phone__c,
                   tsanetconnect__EngineerName__c, tsanetconnect__EngineerEmail__c,
                   tsanetconnect__TSANetEmail__c, tsanetconnect__EngineerPhone__c,
                   tsanetconnect__Email__c, tsanetconnect__Case__c,
                   tsanetconnect__Case__r.CaseNumber, tsanetconnect__Partner__c,
                   tsanetconnect__SubmittedCompanyName__c, tsanetconnect__SubmittedCompanyId__c,
                   tsanetconnect__receivedCompanyName__c, tsanetconnect__receivedCompanyId__c,
                   tsanetconnect__Summary__c, tsanetconnect__Description__c,
                   tsanetconnect__Status__c, tsanetconnect__Token__c,
                   tsanetconnect__Responded__c, tsanetconnect__FeedbackRequested__c,
                   tsanetconnect__ReminderSent__c, tsanetconnect__Priority__c,
                   tsanetconnect__tsaNetCaseId__c, tsanetconnect__RequestDate__c,
                   tsanetconnect__ResponseDate__c, tsanetconnect__PriorityNote__c,
                   tsanetconnect__Direction__c, tsanetconnect__DocumentId__c,
                   tsanetconnect__DocumentName__c,
                   (SELECT Id, Name, tsanetconnect__TSANetCase__c, tsanetconnect__Type__c,
                           tsanetconnect__EngineerName__c, tsanetconnect__EngineerPhone__c,
                           tsanetconnect__EngineerEmail__c, tsanetconnect__Note__c,
                           tsanetconnect__tsaNetCaseId__c, tsanetconnect__tsaNetResponseId__c
                    FROM tsanetconnect__TSANetResponses__r
                    ORDER BY tsanetconnect__CreatedAt__c DESC),
                   (SELECT Id, Name, tsanetconnect__Summary__c, tsanetconnect__Description__c,
                           tsanetconnect__DescriptionPlainText__c, tsanetconnect__CreatorName__c,
                           tsanetconnect__CompanyName__c, tsanetconnect__CreatedAt__c,
                           tsanetconnect__Status__c, tsanetconnect__Priority__c
                    FROM tsanetconnect__TSANetNotes__r
                    ORDER BY tsanetconnect__CreatedAt__c ASC)
            FROM tsanetconnect__TSANetCase__c
            WHERE tsanetconnect__Case__c = :caseId
            WITH USER_MODE
            ORDER BY tsanetconnect__RequestDate__c DESC
        ];
    }

    /**
     * Full detail with responses subquery, filtered by parent Case CaseNumber.
     * @param caseNumber the parent Case CaseNumber
     * @return list of TSANetCase records with responses
     */
    public static tsanetconnect__TSANetCase__c[] getDetailWithResponsesByCaseNumber(String caseNumber) {
        return [
            SELECT Id, Name, tsanetconnect__Name__c, tsanetconnect__customFields__c,
                   tsanetconnect__TSANetContact__c,
                   tsanetconnect__FirstName__c, tsanetconnect__LastName__c, tsanetconnect__Phone__c,
                   tsanetconnect__EngineerName__c, tsanetconnect__EngineerEmail__c,
                   tsanetconnect__TSANetEmail__c, tsanetconnect__EngineerPhone__c,
                   tsanetconnect__Email__c, tsanetconnect__Case__c,
                   tsanetconnect__Case__r.CaseNumber, tsanetconnect__Partner__c,
                   tsanetconnect__SubmittedCompanyName__c, tsanetconnect__SubmittedCompanyId__c,
                   tsanetconnect__receivedCompanyName__c, tsanetconnect__receivedCompanyId__c,
                   tsanetconnect__Summary__c, tsanetconnect__Description__c,
                   tsanetconnect__Status__c, tsanetconnect__Token__c,
                   tsanetconnect__Responded__c, tsanetconnect__FeedbackRequested__c,
                   tsanetconnect__ReminderSent__c, tsanetconnect__Priority__c,
                   tsanetconnect__tsaNetCaseId__c, tsanetconnect__RequestDate__c,
                   tsanetconnect__ResponseDate__c, tsanetconnect__PriorityNote__c,
                   tsanetconnect__Direction__c, tsanetconnect__DocumentId__c,
                   tsanetconnect__DocumentName__c,
                   (SELECT Id, Name, tsanetconnect__TSANetCase__c, tsanetconnect__Type__c,
                           tsanetconnect__EngineerName__c, tsanetconnect__EngineerPhone__c,
                           tsanetconnect__EngineerEmail__c, tsanetconnect__Note__c,
                           tsanetconnect__tsaNetCaseId__c, tsanetconnect__tsaNetResponseId__c
                    FROM tsanetconnect__TSANetResponses__r
                    ORDER BY tsanetconnect__CreatedAt__c DESC)
            FROM tsanetconnect__TSANetCase__c
            WHERE tsanetconnect__Case__r.CaseNumber = :caseNumber
            WITH USER_MODE
            ORDER BY tsanetconnect__RequestDate__c DESC
        ];
    }

    /**
     * Action fields (approve/reject/close/info/notes) by token.
     * @param token the TSANet case token
     * @return matching TSANetCase record
     */
    public static tsanetconnect__TSANetCase__c getByToken(String token) {
        return [
            SELECT Id, Name, tsanetconnect__Token__c, tsanetconnect__Case__c,
                   tsanetconnect__tsaNetCaseId__c
            FROM tsanetconnect__TSANetCase__c
            WHERE tsanetconnect__Token__c = :token
            WITH USER_MODE
        ];
    }

    /**
     * Action fields by record Id.
     * @param recordId the TSANetCase record Id
     * @return matching TSANetCase record
     */
    public static tsanetconnect__TSANetCase__c getById(Id recordId) {
        return [
            SELECT Id, tsanetconnect__Case__c, tsanetconnect__Token__c,
                   tsanetconnect__tsaNetCaseId__c
            FROM tsanetconnect__TSANetCase__c
            WHERE Id = :recordId
            WITH USER_MODE
        ];
    }

    /**
     * Id-only lookup by token.
     * @param token the TSANet case token
     * @return matching TSANetCase record with Id only
     */
    public static tsanetconnect__TSANetCase__c getIdByToken(String token) {
        return [
            SELECT Id
            FROM tsanetconnect__TSANetCase__c
            WHERE tsanetconnect__Token__c = :token
            WITH USER_MODE
        ];
    }

    /**
     * Trigger helper fields by external case IDs — superset for note/response triggers.
     * @param externalIds set of external TSANet case Ids
     * @return list of matching TSANetCase records
     */
    public static tsanetconnect__TSANetCase__c[] getByExternalCaseIds(Set<String> externalIds) {
        return [
            SELECT Id, Name, OwnerId, tsanetconnect__Case__c, tsanetconnect__tsaNetCaseId__c,
                   tsanetconnect__Partner__c, tsanetconnect__EngineerName__c,
                   tsanetconnect__EngineerPhone__c, tsanetconnect__EngineerEmail__c
            FROM tsanetconnect__TSANetCase__c
            WHERE tsanetconnect__tsaNetCaseId__c IN :externalIds
            WITH USER_MODE
        ];
    }

    /**
     * Feed-item helper fields by record Ids.
     * @param ids set of TSANetCase record Ids
     * @return list of matching TSANetCase records
     */
    public static tsanetconnect__TSANetCase__c[] getByIds(Set<Id> ids) {
        return [
            SELECT Id, Name, tsanetconnect__Case__c, tsanetconnect__Partner__c
            FROM tsanetconnect__TSANetCase__c
            WHERE Id IN :ids
            WITH USER_MODE
        ];
    }

    /**
     * Minimal lookup for owner-sync trigger.
     * @param caseIds set of parent Case Ids
     * @return list of matching TSANetCase records
     */
    public static tsanetconnect__TSANetCase__c[] getByCaseIds(Set<Id> caseIds) {
        return [
            SELECT Id, Name
            FROM tsanetconnect__TSANetCase__c
            WHERE tsanetconnect__Case__c IN :caseIds
            WITH USER_MODE
        ];
    }

    /**
     * TSANet case info for the record-page modal.
     * @param recordId the TSANetCase record Id
     * @return list of matching TSANetCase records
     */
    public static tsanetconnect__TSANetCase__c[] getInfoById(Id recordId) {
        return [
            SELECT Id, tsanetconnect__SubmittedCompanyName__c,
                   tsanetconnect__receivedCompanyName__c, tsanetconnect__Case__c,
                   tsanetconnect__Token__c, tsanetconnect__tsaNetCaseId__c
            FROM tsanetconnect__TSANetCase__c
            WHERE Id = :recordId
            WITH USER_MODE
        ];
    }

    /**
     * Record-page header info.
     * @param caseId the TSANetCase record Id
     * @return matching TSANetCase record
     */
    public static tsanetconnect__TSANetCase__c getRecordPageInfo(Id caseId) {
        return [
            SELECT Id, Name, tsanetconnect__tsaNetCaseId__c,
                   tsanetconnect__customFields__c,
                   tsanetconnect__Case__r.Id, tsanetconnect__Case__r.CaseNumber
            FROM tsanetconnect__TSANetCase__c
            WHERE Id = :caseId
            WITH USER_MODE
        ];
    }

    /**
     * Minimal fields for file-attachment and one-off lookups.
     * @param caseId the TSANetCase record Id
     * @return matching TSANetCase record
     */
    public static tsanetconnect__TSANetCase__c getMinimalById(Id caseId) {
        return [
            SELECT Id, tsanetconnect__tsaNetCaseId__c, tsanetconnect__Case__c
            FROM tsanetconnect__TSANetCase__c
            WHERE Id = :caseId
            WITH USER_MODE
        ];
    }

}
