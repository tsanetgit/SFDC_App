/** Centralized SOQL for Case. */
public with sharing class CaseSelector {

    /**
     * Full detail including Owner, Account, and Contact relationship fields.
     * @param caseId the Case record Id
     * @return Case with all detail fields populated
     */
    public static Case getFullDetailById(Id caseId) {
        return [
            SELECT Id, Subject, CaseNumber, Description,
                   OwnerId, Owner.Name, Owner.FirstName, Owner.LastName, Owner.Phone, Owner.Email,
                   AccountId, Account.Name,
                   ContactId, Contact.Name, Contact.FirstName, Contact.LastName, Contact.Email, Contact.Phone
            FROM Case
            WHERE Id = :caseId
            WITH USER_MODE
        ];
    }

    /**
     * Minimal fields for collaboration-case lookup.
     * @param caseId the Case record Id
     * @return Case with Id and CaseNumber
     */
    public static Case getById(Id caseId) {
        return [
            SELECT Id, CaseNumber
            FROM Case
            WHERE Id = :caseId
            WITH USER_MODE
        ];
    }

    /**
     * Owner detail for PATCH sync back to TSANet.
     * @param caseId the Case record Id
     * @return Case with owner detail fields
     */
    public static Case getOwnerDetailById(Id caseId) {
        return [
            SELECT Id, CaseNumber, OwnerId, Owner.Name, Owner.Phone, Owner.Email
            FROM Case
            WHERE Id = :caseId
            WITH USER_MODE
        ];
    }

    /**
     * Bulk lookup by case numbers (trigger use).
     * @param caseNumbers set of case numbers to query
     * @return list of matching Case records
     */
    public static Case[] getByCaseNumbers(Set<String> caseNumbers) {
        return [
            SELECT Id, OwnerId, CaseNumber
            FROM Case
            WHERE CaseNumber IN :caseNumbers
            WITH USER_MODE
        ];
    }

    /**
     * Recently-viewed cases for picklist.
     * @return up to 10 recently viewed Case records
     */
    public static Case[] getRecent() {
        return [
            SELECT Id, CaseNumber, Subject
            FROM Case
            WITH USER_MODE
            ORDER BY LastViewedDate DESC
            LIMIT 10
        ];
    }

    /**
     * Case search by number or subject.
     * @param searchText case number or subject to match
     * @return list of matching Case records
     */
    public static Case[] search(String searchText) {
        return [
            SELECT Id, CaseNumber, Subject
            FROM Case
            WHERE (CaseNumber = :searchText OR Subject = :searchText)
            WITH USER_MODE
        ];
    }
}
